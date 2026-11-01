{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.firewall;

  ruleModule = types.submodule (
    { name, ... }: {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether this rule is active. Set to false from another module to disable it.";
        };

        proto = mkOption {
          type = types.enum [
            "tcp"
            "udp"
            "tcp-udp"
          ];
          default = "tcp";
          description = "Protocol this rule accepts.";
        };

        ports = mkOption {
          type = types.listOf types.port;
          description = "Ports to accept.";
        };

        interfaces = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "eth0" ];
          description = "Restrict this rule to specific inbound interfaces. Empty = all interfaces.";
        };

        comment = mkOption {
          type = types.str;
          default = name;
          description = "Comment attached to the generated nftables rule.";
        };
      };
    }
  );

  enabledRules = filterAttrs (_: r: r.enable) cfg.rules;

  protosOf =
    r:
    if r.proto == "tcp-udp" then
      [
        "tcp"
        "udp"
      ]
    else
      [ r.proto ];
  portSet = r: "{ ${concatMapStringsSep ", " toString r.ports} }";

  renderProto =
    r: proto:
    if r.interfaces == [ ] then
      ''${proto} dport ${portSet r} accept comment "${r.comment}"''
    else
      concatMapStringsSep "\n          " (
        iface: ''iifname "${iface}" ${proto} dport ${portSet r} accept comment "${r.comment}"''
      ) r.interfaces;

  renderRule = _: r: concatMapStringsSep "\n          " (renderProto r) (protosOf r);
in
{
  options.modules.firewall = {
    enable = mkEnableOption "nftables firewall (default deny inbound) with named, composable rules";

    trustedInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "tailscale0" ];
      description = "Interfaces whose inbound traffic is fully trusted, bypassing all filtering.";
    };

    rules = mkOption {
      type = types.attrsOf ruleModule;
      default = { };
      description = ''
        Named firewall rules, meant to be defined from per-service files

        Add a rule:    modules.firewall.rules.my-service.ports = [ 8080 ];
        Edit a rule:   set any field again for the same name from another module, it merges.
        Remove a rule: modules.firewall.rules.my-service.enable = false;
      '';
      example = literalExpression ''
        {
          adguardhome-web = { proto = "tcp"; ports = [ 3000 ]; };
          adguardhome-dns = { proto = "tcp-udp"; ports = [ 53 ]; };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.etc."nftables.conf".text = ''
      flush ruleset

      table inet filter {
        chain input {
          type filter hook input priority 0; policy drop;

          iif "lo" accept
          ${concatMapStringsSep "\n          " (iface: ''iif "${iface}" accept'') cfg.trustedInterfaces}
          ct state established,related accept
          ct state invalid drop

          icmp type echo-request limit rate 5/second accept
          icmpv6 type echo-request limit rate 5/second accept

          ${concatStringsSep "\n          " (mapAttrsToList renderRule enabledRules)}

          limit rate 5/minute log prefix "nft-drop-in: "
        }

        chain forward {
          type filter hook forward priority 0; policy drop;
        }

        chain output {
          type filter hook output priority 0; policy accept;
        }
      }
    '';

    finit.tasks.nftables-setup = {
      description = "Load nftables firewall ruleset";
      runlevels = "S";
      command = "${pkgs.nftables}/bin/nft -f /etc/nftables.conf";
    };

    environment.systemPackages = with pkgs; [
      nftables
      sbctl
      efibootmgr
    ];
  };
}
