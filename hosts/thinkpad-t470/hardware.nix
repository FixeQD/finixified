{ pkgs, ... }:

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
    device = "/dev/nvme0n1";
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
            mountOptions = [ "fmask=0022" "dmask=0022" ];
          };
        };

        swap = {
          size = "18G";
          content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = true;
          };
        };

        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-L" "ThinkPadFS" "-f" ];
            subvolumes = {
              "@"           = { mountpoint = "/";           mountOptions = btrfsOpts; };
              "@home"       = { mountpoint = "/home";       mountOptions = btrfsOpts; };
              "@opt"        = { mountpoint = "/opt";        mountOptions = btrfsOpts; };
              "@var_log"    = { mountpoint = "/var/log";    mountOptions = btrfsOpts; };
              "@nix"        = { mountpoint = "/nix";        mountOptions = btrfsOpts; };
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
    options = [ "rw" "nosuid" "nodev" "relatime" "size=4G" "mode=1777" ];
  };

  programs.zzz.enable = true;

  hardware.cpu.intel.updateMicrocode = true;

  hardware.firmware = [ pkgs.sof-firmware pkgs.alsa-firmware ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };
}
