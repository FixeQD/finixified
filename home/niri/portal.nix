{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;

    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk
    ];

    config.niri = {
      default = [
        "kde"
        "gtk"
      ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "kde" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "kde" ];
      "org.freedesktop.impl.portal.RemoteDesktop" = [ "kde" ];
      "org.freedesktop.impl.portal.Inhibit" = [ "kde" ];
      "org.freedesktop.impl.portal.Settings" = [ "kde" ];
      "org.freedesktop.impl.portal.DynamicLauncher" = [ "kde" ];
      "org.freedesktop.impl.portal.Wallpaper" = [ "kde" ];
      "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Print" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.Account" = [ "gtk" ];
      "org.freedesktop.impl.portal.Background" = [ "gtk" ];
      "org.freedesktop.impl.portal.Email" = [ "gtk" ];
      "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };
}
