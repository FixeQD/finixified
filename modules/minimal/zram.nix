{ finix, lib, config, ... }:
with lib;
let cfg = config.modules.zram; in
{
  imports = [ finix.nixosModules.zram-swap ];

  options.modules.zram = {
    enable = mkEnableOption "zram swap with zstd";

    memoryPercent = mkOption {
      type = types.ints.positive;
      default = 50;
      description = "Size of the zram device as a percentage of total memory.";
    };

    priority = mkOption {
      type = types.int;
      default = 5;
      description = "Swap priority of the zram device.";
    };
  };

  config = mkIf cfg.enable {
    services.zram-swap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = cfg.memoryPercent;
      priority = cfg.priority;
    };
  };
}
