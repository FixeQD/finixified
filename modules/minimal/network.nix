{ pkgs, lib, config, community-modules, finix, ... }:
with lib;
let cfg = config.modules.network; in
{
  imports = [
    community-modules.nixosModules.tailscale
    finix.nixosModules.iwd
    finix.nixosModules.dhcpcd
    finix.nixosModules.openssh
  ];

  options.modules.network = {
    enable = mkEnableOption "iwd and dhcpcd networking";

    tailscale = {
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

    openssh = {
      enable = mkEnableOption "OpenSSH server";

      permitRootLogin = mkOption {
        type = types.enum [ "yes" "without-password" "prohibit-password" "forced-commands-only" "no" ];
        default = "prohibit-password";
        description = "Whether the root user can login using ssh.";
      };

      passwordAuthentication = mkOption {
        type = types.bool;
        default = false;
        description = "Whether password authentication is allowed.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.iwd.enable = true;

    networking.hosts = {
      "127.0.0.1" = [ "localhost" ];
      "127.0.0.2" = [ config.networking.hostName ];
    };

    services.dhcpcd.enable = true;
    services.dhcpcd.settings = {
      static = "domain_name_servers=1.1.1.2 1.0.0.2";
    };

    environment.systemPackages = with pkgs; [
      iwd
      dhcpcd
    ];

    services.tailscale = mkIf cfg.tailscale.enable {
      enable = true;
      authKeyFile = cfg.tailscale.authKeyFile;
      extraUpFlags = cfg.tailscale.extraUpFlags;
    };

    services.openssh = mkIf cfg.openssh.enable {
      enable = true;
      settings = {
        PermitRootLogin = cfg.openssh.permitRootLogin;
        PasswordAuthentication = cfg.openssh.passwordAuthentication;
      };
    };
  };
}
