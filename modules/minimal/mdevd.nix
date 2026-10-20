{ lib, config, ... }:
with lib;
let cfg = config.modules.mdevd; in
{
  imports = [ ../mdevd ];

  options.modules.mdevd.enable = mkEnableOption "mdevd device manager";

  config = mkIf cfg.enable {
    services.mdevd = {
      enable = true;
      nlgroups = 4;
    };
  };
}
