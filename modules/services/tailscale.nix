{ pkgs, lib, config, community-modules, ... }:
with lib;
let
  cfg = config.modules.tailscale;
  tailscale = config.services.tailscale.package;

  cockpitConf = "/run/cockpit/xdg/cockpit/cockpit.conf";

  # Always exits 0: when not connected to a tailnet, Cockpit just starts without the extra origin.
  cockpitOrigin = pkgs.writeShellScript "cockpit-tailscale-origin" ''
    ${pkgs.coreutils}/bin/rm -f ${cockpitConf}

    json=$(${tailscale}/bin/tailscale whoami --json 2>/dev/null) || exit 0
    name=$(printf '%s' "$json" | ${pkgs.jq}/bin/jq -r '.Node.Name // empty' | ${pkgs.gnused}/bin/sed 's/\.$//')
    [ -n "$name" ] || exit 0

    ${pkgs.coreutils}/bin/mkdir -p ${dirOf cockpitConf}
    printf '[WebService]\nOrigins = %s https://%s\n' "${concatStringsSep " " config.modules.cockpit.allowedOrigins}" "$name" > ${cockpitConf}
  '';
in
{
  imports = [
    community-modules.nixosModules.tailscale
    ./cockpit.nix
  ];

  options.modules.tailscale = {
    enable = mkEnableOption "Tailscale VPN";

    authKeyFile = mkOption {
      type = with types; nullOr path;
      default = null;
      description = "Path to a file containing the Tailscale auth key (e.g. an sops secret path). If unset, `tailscale up` must be run manually.";
    };

    extraUpFlags = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "--ssh" "--advertise-exit-node" ];
      description = "Extra flags passed to `tailscale up`.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.tailscale = {
        enable = true;
        authKeyFile = cfg.authKeyFile;
        extraUpFlags = cfg.extraUpFlags;
      };
    }

    # Cockpit behind `tailscale serve`: allow this host's tailnet name as an origin. 
    # The name is only known at runtime, so a task writes it before Cockpit starts.
    (mkIf config.modules.cockpit.enable {
      modules.cockpit.settings.WebService.ProtocolHeader = mkDefault "X-Forwarded-Proto";

      finit.tasks.cockpit-tailscale-origin = {
        description = "Add the tailnet hostname to Cockpit origins";
        conditions = [ "service/tailscaled/ready" ];
        command = "${cockpitOrigin}";
        log = true;
      };

      finit.services.cockpit.conditions = [ "task/cockpit-tailscale-origin/success" ];
    })
  ]);
}
