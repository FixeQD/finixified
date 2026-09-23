{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.mdevd; in
{
  options.modules.mdevd.enable = mkEnableOption "mdevd device manager";

  config = mkIf cfg.enable {
    services.mdevd = {
      enable = true;
      nlgroups = 4;
    };

    services.gardendevd.enable = false;
    services.gardendevd.debug = false;
  };
}
