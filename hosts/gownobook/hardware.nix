{ pkgs, community-modules, ... }:

let
  btrfsOpts = [
    "noatime"
    "compress=zstd:1"
    "ssd"
    "discard=async"
    "space_cache=v2"
    "X-mount.mkdir"
  ];
in
{
  imports = [ community-modules.nixosModules.openrgb ];

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
            mountOptions = [ "fmask=0022" "dmask=0022" "X-mount.mkdir" ];
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
            extraArgs = [ "-L" "GownoFS" "-f" ];
            postCreateHook = ''
              mkdir -p /mnt/persist/var/lib /mnt/persist/etc/ssh
              mkdir -p /mnt/persist/sops/age /mnt/persist/user-passwords
              chmod 700 /mnt/persist/sops/age /mnt/persist/user-passwords
              ${pkgs.dbus}/bin/dbus-uuidgen --ensure=/mnt/persist/machine-id
            '';
            subvolumes = {
              # "@" (root) removed: "/" is a tmpfs (impermanent)
              "@home"      = { mountpoint = "/home";      mountOptions = btrfsOpts; };
              "@opt"       = { mountpoint = "/opt";       mountOptions = btrfsOpts; };
              "@var_log"   = { mountpoint = "/var/log";   mountOptions = btrfsOpts; };
              "@nix"       = { mountpoint = "/nix";       mountOptions = btrfsOpts; };
              "@persist" = {
                mountpoint = "/persist";
                mountOptions = btrfsOpts;
              };
#              "@snapshots" = { mountpoint = "/.snapshots"; mountOptions = btrfsOpts; };
            };
          };
        };

      };
    };
  };

  fileSystems."/nix".neededForBoot = true;

  fileSystems."/persist".neededForBoot = true;

  fileSystems."/var/lib" = {
    device = "/persist/var/lib";
    fsType = "none";
    options = [ "bind" "X-mount.mkdir" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  fileSystems."/etc/ssh" = {
    device = "/persist/etc/ssh";
    fsType = "none";
    options = [ "bind" "X-mount.mkdir" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  fileSystems."/etc/machine-id" = {
    device = "/persist/machine-id";
    fsType = "none";
    options = [ "bind" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  fileSystems."/etc/sops" = {
    device = "/persist/sops";
    fsType = "none";
    options = [ "bind" "X-mount.mkdir" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  fileSystems."/etc/user-passwords" = {
    device = "/persist/user-passwords";
    fsType = "none";
    options = [ "bind" "X-mount.mkdir" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "rw" "nosuid" "nodev" "relatime" "size=50%" "mode=755" ];
  };

  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "rw" "nosuid" "nodev" "relatime" "size=4G" "mode=1777" ];
  };

  programs.modprobe.blacklist = [
#    "fjes"
#    "spi_nor"
  ];

  # ── GPU: Intel Arc Graphics (Meteor Lake, integrated only) ──────────────────

  hardware.cpu.intel.updateMicrocode = true;

  hardware.firmware = [ pkgs.sof-firmware pkgs.alsa-firmware ];

  services.hardware.openrgb = {
    enable = true;
    motherboard = "intel";
  };

  hardware.graphics = {
    enable    = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      intel-compute-runtime
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };
}
