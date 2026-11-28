{
  pkgs,
  lib,
  config,
  community-modules,
  finix,
  ...
}:
with lib;
let
  cfg = config.modules.desktop;

in
{
  imports = [
    community-modules.nixosModules.fastfetch

    finix.nixosModules.brightnessctl
    finix.nixosModules.niri
    finix.nixosModules.gvfs
    finix.nixosModules.upower
    finix.nixosModules.xwayland-satellite
    finix.nixosModules.zzz
    finix.nixosModules.sessiond-uaccess
  ];

  options.modules.desktop.enable = mkEnableOption "niri desktop and seatd";

  config = mkIf cfg.enable {
    services.gvfs.enable = true;

    services.seatd.enable = true;

    programs.niri = {
      enable = true;
    };

    services.upower.enable = true;

    services.sessiond.enable = true;
    services.sessiond-hooks.enable = true;
    services.sessiond-uaccess.enable = true;
    services.sessiond-power.enable = true;

    programs.brightnessctl.enable = true;

    programs.zzz.enable = true;

    programs.xwayland-satellite.enable = true;

    programs.fastfetch.enable = true;

    environment = {
      variables = {
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };

      systemPackages = with pkgs; [
        appimage-run
        bibata-cursors
        ddcutil
        gobject-introspection
        gtk3
        gtk4
        kdePackages.breeze-icons
        wrapGAppsHook4
        xdg-user-dirs
      ] ++ [
        (python3.withPackages (
          ps: with ps; [
            pygobject3
          ]
        ))
      ];

      pathsToLink = [
        "/share/icons"
        "/share/wayland-sessions"
        "/share/xdg-desktop-portal"
        "/etc/xdg"
      ];
    };

    xdg.portal = {
      enable = true;
      portals = [
        pkgs.kdePackages.xdg-desktop-portal-kde
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    services.dbus.packages = [ pkgs.dconf ];
  };
}
