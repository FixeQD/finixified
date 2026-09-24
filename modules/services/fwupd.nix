{ lib, config, finix, ... }:
with lib;
let cfg = config.modules.fwupd; in
{
  imports = [ finix.nixosModules.fwupd ];

  options.modules.fwupd.enable = mkEnableOption "Firmware update daemon";

  config = mkIf cfg.enable {
    services.fwupd.enable = true;
  };
}
