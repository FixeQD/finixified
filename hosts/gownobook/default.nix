{
  pkgs,
  disko,
  community-modules,
  finix,
  zen-browser,
  spicetify-nix,
  noctalia,
  nixcord,
  ...
}:
{
  specialArgs = {
    inherit disko community-modules finix zen-browser spicetify-nix noctalia nixcord;
  };

  modules = [
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
        ../../modules/desktop/virt.nix

        ../../modules/installer.nix
        ../../modules/services/fwupd.nix
        ../../modules/services/ollama.nix
        ../../modules/services/secrets.nix
        ../../modules/firewall/default.nix

        community-modules.nixosModules.home-manager
      ];

      networking.hostName = "gownobook";

      modules = {
        audio.enable = true;
        base.enable = true;
        bluetooth.enable = true;
        cron.enable = true;
        desktop.enable = true;
        desktop.nvidia.enable = false;
        locale.enable = true;
        mdevd.enable = true;
        network.enable = true;
        network.tailscale.enable = true;

        network.openssh.enable = true;
        network.openssh.permitRootLogin = "no";

        installer.requireSops = true;

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
        fwupd.enable = true;
        user.enable = true;
        user.name = "fixeq";
        virt.enable = true;
        zram.enable = true;
        ollama.enable = true;
      };

      home-manager.users.fixeq = {
        _module.args = {
          inherit zen-browser spicetify-nix noctalia;
          username = "fixeq";
        };

        imports = [
          ../../home/default.nix
          spicetify-nix.homeManagerModules.default
          noctalia.homeModules.default
          nixcord.homeModules.nixcord
        ];
      };

      finit.runlevel = 3;
    }
  ];
}
