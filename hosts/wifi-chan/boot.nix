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

  # Plain LTS kernel - this box just routes/serves, no need for -zen's desktop tuning.
  boot.kernelPackages = pkgs.linuxPackages;

  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  boot.initrd = {
    availableKernelModules = [
      "ahci"       # M.2 SATA SSD
      "xhci_pci"
      "usb_storage"
      "sd_mod"
    ];

    supportedFilesystems.btrfs.enable = true;
  };

  # AMD Jaguar-based SoC (GX-420GI) - has AMD-V, useful once containers/VMs land.
  boot.kernelModules = [ "kvm-amd" ];

  boot.kernelParams = [
    "rootflags=subvol=${rootSubvol}"
    "rootfstype=${rootFsType}"
    "zswap.enabled=0"
  ];
}