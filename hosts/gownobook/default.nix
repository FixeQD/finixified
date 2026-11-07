{
  pkgs,
  disko,
  community-modules,
  finix,
  nixcord,
  inputs,
  flakeDir,
  ...
}:
let
  userName = "fixeq";
in
{
  specialArgs = {
    inherit
      disko
      community-modules
      finix
      nixcord
      inputs
      ;
  };

  modules = [
    {
      imports = [
        ./boot.nix
        ./hardware.nix
        ./mdevd

        ../../modules/minimal/base.nix
        ../../modules/minimal/cron.nix
        ../../modules/minimal/locale.nix
        ../../modules/minimal/mdevd.nix
        ../../modules/minimal/network.nix
        ../../modules/minimal/performance.nix
        ../../modules/minimal/ssh.nix
        ../../modules/minimal/zram.nix

        ../../modules/desktop/audio.nix
        ../../modules/desktop/bluetooth.nix
        ../../modules/desktop/dconf.nix
        ../../modules/desktop/desktop.nix
        ../../modules/desktop/fonts.nix
        ../../modules/desktop/nix-ld.nix
        ../../modules/desktop/nixcord.nix
        ../../modules/desktop/virt.nix

        ../../modules/firewall/default.nix
        ../../modules/installer.nix

        ../../modules/services/cloudflared.nix
        ../../modules/services/cockpit.nix
        ../../modules/services/fwupd.nix
        ../../modules/services/ollama.nix
        ../../modules/services/secrets.nix
        ../../modules/services/tailscale.nix
        ../../modules/services/vnc-server.nix

        inputs.hjem.finixModules.default
      ];

      networking.hostName = "gownobook";

      modules = {
        audio.enable = true;
        base.enable = true;
        bluetooth.enable = true;
        dconf.enable = true;
        cron.enable = true;
        desktop.enable = true;
        desktop.nvidia.enable = false;
        locale.enable = true;
        mdevd.enable = true;
        network.enable = true;

        ssh.openssh.enable = true;
        ssh.openssh.permitRootLogin = "no";

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
          openvino
          ocl-icd
          level-zero
          intel-compute-runtime
        ];

        performance.enable = true;
        firewall.enable = true;
        firewall.trustedInterfaces = [
          "tailscale0"
          "br-metamcp"
        ];
        fwupd.enable = true;
        ollama.enable = true;
        tailscale = {
          enable = true;
          oauth = true;
          tags = [ "tag:laptop" ];
        };
        user.enable = true;
        user.name = userName;
        virt.enable = true;
        zram.enable = true;
        cloudflared = {
          enable = true;
          tokenFile = "/run/secrets/gownobook_cloudflared_token";
        };
        cockpit = {
          enable = true;
          package = pkgs.cockpit.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              substituteInPlace src/cockpit/channels/dbus.py \
                --replace-fail "if err.errno != errno.EBUSY:" \
                               "if err.errno not in (errno.EBUSY, errno.EINVAL):"
            '';
          });

          plugins = with pkgs; [
            cockpit-machines
            cockpit-files
            cockpit-dockermanager
          ];
          allowedOrigins = [ "https://gownobook.rohu-tint.ts.net" ];
        };
        vncServer = {
          enable = true;
          output = "eDP-1";
        };
      };

      hjem = {
        clobberByDefault = true;

        extraModules = [
          inputs.hjem-rum.hjemModules.default
          inputs.spicetify-nix.hjemModules.default
          inputs.exo.hjemModules.default
          ../../hjem
        ];
        specialArgs = { inherit inputs flakeDir; };

        users.${userName} = {
          enable = true;
        };
      };

      finit.runlevel = 3;
    }
  ];
}
