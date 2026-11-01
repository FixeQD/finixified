{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.performance;
in
{
  options.modules.performance.enable = mkEnableOption "sysctl tweaks and NVMe scheduler";

  config = mkIf cfg.enable {
    boot.kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
      "vm.dirty_background_bytes" = 67108864;
      "vm.dirty_bytes" = 268435456;
      "vm.dirty_expire_centisecs" = 3000;
      "vm.dirty_writeback_centisecs" = 1500;
    };

    services.udev.packages = [
      (pkgs.writeTextDir "etc/udev/rules.d/60-nvme-scheduler.rules" ''
        ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
      '')
    ];

    environment.systemPackages = [
      config.boot.kernelPackages.cpupower
    ];
  };
}
