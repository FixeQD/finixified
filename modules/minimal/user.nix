{
  pkgs,
  lib,
  config,
  finix,
  ...
}:
with lib;
let
  cfg = config.modules.user;
in
{
  imports = [
    finix.nixosModules.sudo
  ];

  options.modules.user = {
    enable = mkEnableOption "primary user and sudo";
    name = mkOption {
      type = types.str;
      description = "Primary user login name";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.name;
      shell = pkgs.fish;
      passwordFile = "/persist/user-passwords/${cfg.name}";
      extraGroups = [
        "wheel"
        "seat"
        "storage"
        "power"
        "audio"
        "video"
        "optical"
        "network"
        "input"
        "docker"
        "libvirtd"
        "kvm"
        "adbusers"
        "fido"
      ];
    };

    users.users.root.passwordFile = "/persist/user-passwords/root";

    programs.sudo.enable = true;
  };
}
