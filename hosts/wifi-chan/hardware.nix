{ pkgs, lib, ... }:

let
  btrfsOpts = [
    "noatime"
    "compress=zstd:1"
    "ssd"
    "discard=async"
    "space_cache=v2"
  ];
in
{
  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0022"
              "dmask=0022"
            ];
          };
        };

        swap = {
          size = "2G";
          content = {
            type = "swap";
            discardPolicy = "both";
          };
        };

        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "-L"
              "T630FS"
              "-f"
            ];
            subvolumes = {
              "@" = {
                mountpoint = "/";
                mountOptions = btrfsOpts;
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = btrfsOpts;
              };
              "@opt" = {
                mountpoint = "/opt";
                mountOptions = btrfsOpts;
              };
              "@var_log" = {
                mountpoint = "/var/log";
                mountOptions = btrfsOpts;
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = btrfsOpts;
              };
              "@var_lib" = {
                mountpoint = "/var/lib";
                mountOptions = btrfsOpts;
              };
            };
          };
        };

      };
    };
  };

  fileSystems."/nix".neededForBoot = true;

  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "rw"
      "nosuid"
      "nodev"
      "relatime"
      "size=1G"
      "mode=1777"
    ];
  };

  hardware.cpu.amd.updateMicrocode = true;

}
