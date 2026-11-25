{
  pkgs,
  config,
  lib,
  community-modules,
  ...
}:

let
  rootFsType = config.fileSystems."/".fsType;

  rootSubvolOption = lib.findFirst (lib.hasPrefix "subvol=") null (
    config.fileSystems."/".options or [ ]
  );
  rootSubvol =
    if rootFsType == "btrfs" then
      if rootSubvolOption != null then
        lib.removePrefix "subvol=" rootSubvolOption
      else
        throw "boot.nix: subvol= not found in fileSystems.\"/\".options"
    else
      null;
in
{
  imports = [ community-modules.nixosModules.efistubmgr ];

  programs.efistubmgr = {
    enable = true;
    maxGenerations = 3;

    bootEntry = ''$LABEL''${REV:+ $REV} ❖ $(${lib.getExe' config.programs.coreutils.package "date"} -d "@$TIMESTAMP" '+%Y-%m-%d %H:%M:%S %Z')'';
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  boot.initrd = {
    availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usb_storage"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];
    kernelModules = [ "i915" ];

    supportedFilesystems.btrfs.enable = true;
    compressor = "cat";
  };

  boot.kernelModules = [ "kvm-intel" ];

  boot.kernelParams =
    (lib.optionals (rootFsType == "btrfs") [
      "rootflags=subvol=${rootSubvol}"
    ])
    ++ [
      "rootfstype=${rootFsType}"
      "zswap.enabled=0"
      "snd_intel_dspcfg.dsp_driver=1"
    ]
    ++ [
      "slab_nomerge"
      "init_on_alloc=1"
      "page_alloc.shuffle=1"
      "randomize_kstack_offset=on"
      "vsyscall=none"
      "debugfs=off"
      "intel_iommu=on"
      "iommu.strict=1"
      "efi=disable_early_pci_dma"
    ]
    ++ [
      "quiet"
      "loglevel=3"
      "cryptomgr.notests"
      "tsc=reliable"
      "rcupdate.rcu_expedited=1"
      "rcupdate.rcu_normal_after_boot=1"
    ];
}
