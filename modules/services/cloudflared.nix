{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.cloudflared;

  cloudflaredStart = pkgs.writeShellScript "cloudflared-start" ''
    set -euo pipefail
    TOKEN=$(${pkgs.coreutils}/bin/cat "${cfg.tokenFile}")
    exec ${pkgs.cloudflared}/bin/cloudflared tunnel run --token "$TOKEN" ${escapeShellArgs cfg.extraFlags}
  '';
in
{
  options.modules.cloudflared = {
    enable = mkEnableOption "Cloudflare Tunnel (cloudflared)";

    tokenFile = mkOption {
      type = types.path;
      description = ''
        Path to a file containing the Cloudflare Tunnel token (e.g. an sops secret path)
      '';
      example = "/run/secrets/cloudflared_tunnel_token";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--loglevel"
        "debug"
      ];
      description = "Extra flags passed to `cloudflared tunnel run`.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.cloudflared ];

    finit.services.cloudflared = {
      description = "Cloudflare Tunnel";
      runlevels = "2345";
      conditions = [
        "service/syslogd/ready"
        "service/dhcpcd/ready"
      ];
      command = "${cloudflaredStart}";
      respawn = true;
      log = true;
    };
  };
}
