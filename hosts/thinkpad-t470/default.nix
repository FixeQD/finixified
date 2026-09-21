{ config, zen-browser, spicetify-nix, nyth, noctalia, pkgs, nixcord, ... }:
{
  imports = [
    ./hardware.nix
    ./boot.nix

    ../../modules/minimal/base.nix
    ../../modules/minimal/locale.nix
    ../../modules/minimal/network.nix
    ../../modules/minimal/cron.nix
    ../../modules/minimal/performance.nix
    ../../modules/minimal/zram.nix
    ../../modules/minimal/user.nix
    ../../modules/minimal/mdevd.nix

    ../../modules/desktop/fonts.nix
    ../../modules/desktop/audio.nix
    ../../modules/desktop/desktop.nix
    ../../modules/desktop/bluetooth.nix
    ../../modules/desktop/nix-ld.nix
    ../../modules/desktop/nyth.nix
    ../../modules/desktop/virt.nix

    ../../modules/services/cloudflared.nix
    ../../modules/services/secrets.nix
    ../../modules/services/yggdrasil.nix
    ../../modules/services/ollama.nix
    ../../modules/firewall/default.nix
  ];

  networking.hostName = "thinkpad-t470";

  services.sysklogd.enable = true;

  modules = {
    audio.enable = true;
    base.enable = true;
    bluetooth.enable = true;
    cron.enable = true;
    cloudflared.enable = true;
    cloudflared.tokenFile = config.sops.secrets.cloudflared_tunnel_token.path;
    desktop.enable = true;
    desktop.nvidia.enable = false;
    locale.enable = true;
    mdevd.enable = true;
    network.enable = true;
    network.tailscale.enable = true;

    network.openssh.enable = true;
    network.openssh.permitRootLogin = "no";

    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib
      icu
      openssl
      gtk3
      zlib
      pango
      harfbuzz
      atk
      cairo
      gdk-pixbuf
      glib
      curl
      libepoxy
      fontconfig
    ];

    performance.enable = true;
    firewall.enable = true;
    user.enable = true;
    user.name = "fixeq";
    virt.enable = true;
    yggdrasil.enable = true;
    zram.enable = true;
    ollama.enable = true;
  };

  networking.hosts = {
    "127.0.0.1" = [ "localhost" ];
    "127.0.0.2" = [ "thinkpad-t470" ];
  };

  services.hardware.openrgb = {
    enable = true;
    motherboard = "intel";
  };

  services.fwupd.enable = true;

  home-manager.users.${config.modules.user.name} = {
    _module.args = {
      inherit zen-browser spicetify-nix nyth noctalia;
      username = config.modules.user.name;
    };

    imports = [
      ../../home/default.nix
      spicetify-nix.homeManagerModules.default
      nyth.homeManagerModules.default
      noctalia.homeModules.default
      nixcord.homeModules.nixcord
    ];
  };

  finit.runlevel = 3;
}
