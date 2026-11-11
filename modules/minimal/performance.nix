{
  pkgs,
  lib,
  finix,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.performance;
in
{
  imports = [
    finix.nixosModules.earlyoom
    finix.nixosModules.system76-scheduler
  ];

  options.modules.performance.enable = mkEnableOption "sysctl tweaks and NVMe scheduler";

  config = mkIf cfg.enable {
    boot.kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
      "vm.dirty_background_bytes" = 67108864;
      "vm.dirty_bytes" = 268435456;
      "vm.dirty_expire_centisecs" = 3000;
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.vfs_cache_pressure" = 50;
      "kernel.nmi_watchdog" = 0;
    };

    boot.kernelParams = [
      "threadirqs"
      "nowatchdog"
      "transparent_hugepage=madvise"
    ];

    finit.cgroups.system."cpu.weight" = 100;

    finit.services.sessiond.cgroup.system."cpu.weight" = 2000;
    finit.services.nix-daemon.cgroup.system = {
      "cpu.weight" = 20;
      "memory.high" = "11G";
    };
    finit.services.sessiond.cgroup.system."memory.low" = "3G";

    services.nix-daemon.settings = {
      max-jobs = 2;
      cores = 8;
    };

    services.earlyoom = {
      enable = true;
      extraArgs = [
        "-m"
        "4"
        "-s"
        "50"
        "--avoid"
        "^(niri|sessiond|finit)$"
      ];
    };

    services.system76-scheduler = {
      enable = true;
      configFile = pkgs.writeText "system76-scheduler-config.kdl" ''
        version "2.0"
        process-scheduler {
            enable true
            refresh-rate 60
            assignments {
                compile nice=15 sched="batch" io=(best-effort)7 {
                    "cargo"
                    "rustc"
                    "cc1"
                    "cc1plus"
                    "cc"
                    "gcc"
                    "g++"
                    "clang"
                    "clang++"
                    "ld"
                    "ld.bfd"
                    "ld.lld"
                    "lld"
                    "rust-lld"
                    "mold"
                    "ninja"
                    "make"
                    "cmake"
                }
                desktop nice=-5 io=(best-effort)0 {
                    "niri"
                    "xwayland-satellite"
                    "pipewire"
                    "wireplumber"
                    "pipewire-pulse"
                }
            }
        }
      '';
    };

    finit.run.sata-scheduler = {
      description = "set bfq scheduler on SATA disks";
      command = pkgs.writeShellScript "sata-scheduler" ''
        for q in /sys/block/sd*/queue/scheduler; do
          [ -w "$q" ] && echo bfq > "$q"
        done
        exit 0
      '';
      runlevel = "S";
      log = { };
    };

    environment.systemPackages = [
      config.boot.kernelPackages.cpupower
    ];
  };
}
