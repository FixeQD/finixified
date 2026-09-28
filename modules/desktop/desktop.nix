{ pkgs, lib, config, community-modules, finix, ... }:
with lib;
let cfg = config.modules.desktop; in
{
  imports = [
    community-modules.nixosModules.fastfetch

    finix.nixosModules.brightnessctl
    finix.nixosModules.niri
    finix.nixosModules.sddm
    finix.nixosModules.upower
    finix.nixosModules.xwayland-satellite
    finix.nixosModules.zzz
  ];

  options.modules.desktop.enable = mkEnableOption "niri desktop and seatd";
  options.modules.desktop.nvidia.enable = mkEnableOption "NVIDIA desktop environment variables";

  config = mkIf cfg.enable {
    services.seatd.enable = true;

    programs.niri = {
      enable = true;
    };

    services.upower.enable = true;

    services.sessiond.enable = true;

    programs.brightnessctl.enable = true;

    programs.zzz.enable = true;

    programs.xwayland-satellite.enable = true;

    programs.fastfetch.enable = true;

    environment = {
      variables = {
        WLR_NO_HARDWARE_CURSORS             = "1";
        NIXOS_OZONE_WL                      = "1";
        MOZ_ENABLE_WAYLAND                  = "1";
        QT_QPA_PLATFORM                     = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        ELECTRON_OZONE_PLATFORM_HINT        = "auto";
      } // mkIf cfg.nvidia.enable {
        LIBVA_DRIVER_NAME         = "nvidia";
        GBM_BACKEND               = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVD_BACKEND               = "direct";
      };

      systemPackages = with pkgs; [
        bibata-cursors
        ddcutil
        gobject-introspection
        gtk3
        gtk4
        kdePackages.breeze-icons
        wrapGAppsHook4
        (python3.withPackages (ps: with ps; [
          pygobject3
        ]))
      ];

      pathsToLink = [
        "/share/icons"
        "/share/wayland-sessions"
        "/share/xdg-desktop-portal"
      ];
    };

    xdg.portal = {
      enable  = true;
      portals = [
        pkgs.kdePackages.xdg-desktop-portal-kde
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    services.sddm = {
      enable = true;
      extraPackages = [
        pkgs.kdePackages.qtdeclarative
        pkgs.kdePackages.qtsvg
        pkgs.kdePackages.qt5compat
        (pkgs.stdenv.mkDerivation {
          name = "glyph-sddm";
          src = pkgs.fetchFromGitHub {
            owner = "xCaptaiN09";
            repo = "glyph-sddm";
            rev = "main";
            hash = "sha256-A2uncMbcu1+jqCaaEYMV8CICW485XkpbSj2UUs0QeMU=";
          };
          installPhase = "
            mkdir -p $out/share/sddm/themes/glyph
            cp -r * $out/share/sddm/themes/glyph/
          ";
        })
      ];
      settings = {
        Theme = {
          Current = "glyph";
        };
      };
    };

    services.dbus.packages = [ pkgs.dconf ];
  };
}
