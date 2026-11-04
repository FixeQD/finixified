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
      default = attrByPath [ "sops" "secrets" "tailscale_oauth_secret" "path" ] null config;
      description = "Path to a file containing the Tailscale auth key (e.g. an sops secret path). If unset, `tailscale up` must be run manually.";
    };

    oauth = mkEnableOption "treating authKeyFile as an OAuth client secret (tskey-client-...) that mints a fresh auth key on every `tailscale up`";

    tags = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "tag:laptop" ];
      description = "Additional ACL tags for the device. tag:finixified is always included.";
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
      assertions = [
        {
          assertion = cfg.oauth -> cfg.authKeyFile != null;
          message = "modules.tailscale.oauth needs authKeyFile; OAuth clients can only register tagged devices";
        }
      ];

      services.tailscale = {
        enable = true;
        authKeyFile = cfg.authKeyFile;
        authKeyParameters = mkIf cfg.oauth {
          preauthorized = true;
          ephemeral = false;
        };
        extraUpFlags =
          cfg.extraUpFlags ++ [
            "--advertise-tags=${concatStringsSep "," ([ "tag:finixified" ] ++ cfg.tags)}"
          ];
      };
    }
  ]);
}
