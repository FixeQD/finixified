{
  pkgs,
  lib,
  config,
  community-modules,
  ...
}:
with lib;
let
  cfg = config.modules.tailscale;
  tailscale = config.services.tailscale.package;
in
{
  imports = [ community-modules.nixosModules.tailscale ];

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
      example = [
        "--ssh"
        "--advertise-exit-node"
      ];
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
  ]);
}
