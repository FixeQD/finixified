{ lib, config, ... }:
let
  cfg = config.modules.udev;
in
{
  imports = [ ../udev ];

  options.modules.udev.enable = lib.mkEnableOption "eudev device manager";

  config = lib.mkIf cfg.enable {
    services.udev.enable = true;
  };
}
