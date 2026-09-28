{
  pkgs,
  disko,
  community-modules,
  finix,
  nixcord,
  inputs,
  ...
}:
{
  specialArgs = {
    inherit disko community-modules finix nixcord;
  };

  modules = [
    {
      imports = [
        ./boot.nix
        ./hardware.nix

        ../../modules/minimal/base.nix
        ../../modules/minimal/cron.nix
        ../../modules/minimal/locale.nix
        ../../modules/minimal/mdevd.nix
        ../../modules/minimal/network.nix
        ../../modules/minimal/performance.nix
        ../../modules/minimal/user.nix
        ../../modules/minimal/zram.nix

        ../../modules/desktop/audio.nix
        ../../modules/desktop/bluetooth.nix
        ../../modules/desktop/desktop.nix
        ../../modules/desktop/fonts.nix
        ../../modules/desktop/nix-ld.nix
        ../../modules/desktop/nixcord.nix
        ../../modules/desktop/virt.nix

        ../../modules/firewall/default.nix
        ../../modules/installer.nix

        ../../modules/services/cloudflared.nix
        ../../modules/services/fwupd.nix
        ../../modules/services/ollama.nix
        ../../modules/services/secrets.nix

        inputs.hjem.finixModules.default
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
        firewall.trustedInterfaces = [ "tailscale0" "br-metamcp" ];
        fwupd.enable = true;
        user.enable = true;
        user.name = "fixeq";
        virt.enable = true;
        zram.enable = true;
        ollama.enable = true;
        cloudflared = {
          enable = true;
          tokenFile = "/run/secrets/gownobook_cloudflared_token";
        };
      };

      hjem = {
        clobberByDefault = true;

        extraModules = [
          inputs.hjem-rum.hjemModules.default
          inputs.spicetify-nix.hjemModules.default
          inputs.noctalia.hjemModules.default
          ../../hjem
        ];
        specialArgs = { inherit inputs; };

        users.fixeq = {
          enable = true;
        };
      };

      finit.runlevel = 3;
    }
  ];
}
