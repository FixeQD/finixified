{
  pkgs,
  lib,
  config,
  finix,
  ...
}:
with lib;
let
  cfg = config.modules.network;
in
{
  imports = [
    finix.nixosModules.iwd
    finix.nixosModules.dhcpcd
  ];

  options.modules.network = {
    enable = mkEnableOption "iwd and dhcpcd networking";
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
  };
}
