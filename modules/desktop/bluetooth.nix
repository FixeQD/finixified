{ pkgs, lib, config, finix, ... }:
with lib;
let cfg = config.modules.bluetooth; in
{
  imports = [ finix.nixosModules.bluetooth ];

  options.modules.bluetooth.enable = mkEnableOption "Bluetooth daemon";

  config = mkIf cfg.enable {
    services.bluetooth = {
      enable = true;
      settings.Policy.AutoEnable = false;
    };

    environment.systemPackages = with pkgs; [
      bluez
      blueman
    ];
  };
}
