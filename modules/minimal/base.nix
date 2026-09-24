{ pkgs, lib, config, disko, community-modules, finix, ... }:
with lib;
let cfg = config.modules.base; in
{
  imports = [
    disko.nixosModules.disko
    community-modules.nixosModules.bootchart
    finix.nixosModules.getty
    finix.nixosModules.nix-daemon
    finix.nixosModules.sysklogd
  ];

  options.modules.base.enable = mkEnableOption "core packages and Nix settings";

  config = mkIf cfg.enable {
    hardware.firmware = [ pkgs.linux-firmware ];

    environment.systemPackages = with pkgs; [
      btrfs-progs
      util-linux
      coreutils
      wget
      curl
      git
      neovim
      man-pages
      less
      btop
      usbutils
      pciutils
      lshw
      ripgrep
      fd
      bat
      eza
      tree
      tokei
      fwupd
      fish
      starship
      ghostty
      nixd
      nixos-rebuild-ng
      nil
      nh
      glib
      pkg-config
      libxkbcommon.dev
    ];

    users.defaultUserShell = pkgs.fish;

    services.bootchart.enable = true;
    services.bootchart.stop.conditions = [ "service/sddm/ready" ];

    services.getty.enable = true;

    services.sysklogd.enable = true;

    services.nix-daemon = {
      enable = true;
      settings = {
        substituters = [ "https://finix.cachix.org" ];
        trusted-public-keys = [ "finix.cachix.org-1:0ejikHDeCp0UErsduUUHcg9IJczY2/h2e5132Z/As/c=" ];
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store   = true;
        warn-dirty            = false;
        max-jobs              = "auto";
      };
    };
  };
}
