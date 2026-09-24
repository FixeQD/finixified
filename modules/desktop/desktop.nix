{ pkgs, lib, config, community-modules, finix, ... }:
with lib;
let cfg = config.modules.desktop; in
{
  imports = [
    community-modules.nixosModules.fastfetch
    finix.nixosModules.niri
    finix.nixosModules.xwayland-satellite
    finix.nixosModules.sddm
    finix.nixosModules.zzz
    finix.nixosModules.brightnessctl
    finix.nixosModules.upower
  ];

  options.modules.desktop.enable = mkEnableOption "niri desktop and seatd";
  options.modules.desktop.nvidia.enable = mkEnableOption "NVIDIA desktop environment variables";

  config = mkIf cfg.enable {
    services.seatd.enable = true;

    programs.niri = {
      enable = true;
    };

    services.upower.enable = true;

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
        ddcutil
        gobject-introspection
        gtk3
        gtk4
        wrapGAppsHook4
        (python3.withPackages (ps: with ps; [
          pygobject3
        ]))
      ];

      pathsToLink = [
        "/share/wayland-sessions"
      ];
    };

    xdg.portal = {
      enable  = true;
      portals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    services.sddm.enable = true;

    services.dbus.packages = [ pkgs.dconf ];
  };
}
