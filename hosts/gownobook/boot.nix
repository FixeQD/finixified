{ pkgs, config, lib, community-modules, ... }:

let
  rootFsType = config.fileSystems."/".fsType;

  rootSubvolOption = lib.findFirst (lib.hasPrefix "subvol=") null config.fileSystems."/".options;
  rootSubvol =
    if rootSubvolOption != null
    then lib.removePrefix "subvol=" rootSubvolOption
    else throw "boot.nix: subvol= not found in fileSystems.\"/\".options";
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
  };

  boot.kernelModules = [ "kvm-intel" ];

  boot.kernelParams = [
    "rootflags=subvol=${rootSubvol}"
    "rootfstype=${rootFsType}"
    "zswap.enabled=0"
    "snd_intel_dspcfg.dsp_driver=1"
    "intel_pstate.no_turbo=0"
  ];
}
