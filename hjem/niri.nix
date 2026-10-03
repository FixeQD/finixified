{
  lib,
  pkgs,
  ...
}:
let
  terminal = [
    "ghostty"
  ];
  browser = [ "zen" ];
  editor = [ "zeditor" ];

  terminalAppId = "com.mitchellh.ghostty";
  browserAppId = "zen";
  discordAppId = "discord";

  spawn = args: "spawn " + lib.concatMapStringsSep " " (a: ''"${a}"'') args;

  plainBinds = [
    "Mod+o { toggle-overview; }"
    "Mod+q { close-window; }"
    "Mod+v { toggle-window-floating; }"
    "Mod+j { focus-window-down; }"
    "Mod+k { focus-window-up; }"
    "Mod+h { focus-column-left-or-last; }"
    "Mod+l { focus-column-right-or-first; }"
    "Mod+Shift+j { move-window-down; }"
    "Mod+Shift+k { move-window-up; }"
    "Mod+Shift+h { move-column-left-or-to-monitor-left; }"
    "Mod+Shift+l { move-column-right-or-to-monitor-right; }"
    "Mod+Comma { consume-window-into-column; }"
    "Mod+Period { expel-window-from-column; }"
    "Mod+f { maximize-column; }"
    "Mod+Shift+f { fullscreen-window; }"

    "Mod+Control+l { set-column-width \"+10%\"; }"
    "Mod+Control+h { set-column-width \"-10%\"; }"
    "Mod+Control+k { set-window-height \"+10%\"; }"
    "Mod+Control+j { set-window-height \"-10%\"; }"

    "Print { screenshot; }"
    "Shift+Print { screenshot-screen; }"
    "Ctrl+Print { screenshot-window; }"

    "Mod+WheelScrollDown { focus-column-right; }"
    "Mod+WheelScrollUp { focus-column-left; }"
    "Mod+Ctrl+WheelScrollDown { focus-workspace-down; }"
    "Mod+Ctrl+WheelScrollUp { focus-workspace-up; }"
    "Mod+Shift+WheelScrollDown { move-column-right; }"
    "Mod+Shift+WheelScrollUp { move-column-left; }"
    "Mod+MouseMiddle { toggle-overview; }"

    "Mod+Escape { quit; }"

    "Mod+Return { ${spawn terminal}; }"
    "Mod+e { ${spawn (terminal ++ [ "-e" "yazi" ])}; }"
    "Mod+b { ${spawn browser}; }"
    "Mod+c { ${spawn editor}; }"
  ];

  workspaceBinds =
    lib.concatMapStringsSep "\n" (
      n: ''
        Mod+${toString n} { focus-workspace ${toString n}; }
        Mod+Shift+${toString n} { move-window-to-workspace ${toString n}; }''
    ) (lib.range 1 9);

  bindsKdl = ''
    binds {
    ${lib.concatMapStringsSep "\n" (b: "    " + b) plainBinds}

    ${lib.concatMapStringsSep "\n" (b: "    " + b) (lib.splitString "\n" workspaceBinds)}
    }
  '';

  settingsKdl = ''
    prefer-no-csd

    xwayland-satellite {
        path "${lib.getExe pkgs.xwayland-satellite}"
    }

    layout {
        gaps 6
        border {
            width 2
            active-gradient from="#ff0000" to="#ff00ff" angle=45 in="oklch longer hue"
            inactive-gradient from="#7c7f93" to="#45475a" angle=45 in="oklch longer hue"
        }
        focus-ring {
            off
        }
        shadow {
            on
        }
        background-color "#00000000"
        center-focused-column "never"
        default-column-display "normal"
        default-column-width {
            proportion 1.0
        }
    }

    overview {
        workspace-shadow {
            off
        }
    }

    cursor {
        xcursor-theme "Bibata-Modern-Classic"
        xcursor-size 24
        hide-when-typing
        hide-after-inactive-ms 3000
    }

    input {
        keyboard {
            xkb {
                layout "pl"
            }
        }
        focus-follows-mouse {
        }
        touchpad {
            natural-scroll
            dwt
            tap
            middle-emulation
            scroll-factor 1.0
        }
    }

    window-rule {
        geometry-corner-radius 10
        clip-to-geometry true
        draw-border-with-background false
        background-effect {
            xray false
            blur true
        }
    }

    window-rule {
        match is-focused=false
        opacity 0.8
    }

    window-rule {
        match is-focused=true
        opacity 1.0
    }

    window-rule {
        match app-id="^${terminalAppId}$"
        default-column-width {
            proportion 0.5
        }
    }

    window-rule {
        match app-id="^${terminalAppId}$" is-focused=true
        opacity 1.0
        default-column-width {
            proportion 0.5
        }
    }

    window-rule {
        match app-id="^${terminalAppId}$" title="^termfilechooser$"
        open-floating true
        default-column-width {
            fixed 1024
        }
        default-window-height {
            fixed 768
        }
    }

    window-rule {
        match app-id="^${browserAppId}$"
        opacity 1.0
    }

    window-rule {
        match app-id="^${discordAppId}$"
        geometry-corner-radius 0
        border {
            off
        }
    }


    layer-rule {
      match namespace=r#"^noctalia-wallpaper.*"#
      place-within-backdrop true
    }
  '';
in
{
  rum.desktops.niri = {
    enable = true;

    extraVariables = {
      _JAVA_AWT_WM_NONREPARENTING = "1";
      AWT_TOOLKIT = "MToolkit";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland";
      QT_QPA_PLATFORMTHEME = "gtk4";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      SDL_VIDEODRIVER = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NVD_BACKEND = "direct";
      DISPLAY = ":0";
    };

    spawn-at-startup = map (cmd: [ "sh" "-c" cmd ]) [
      "noctalia"
      "polkit-kde-authentication-agent-1"
      "pgrep -x kdeconnectd || kdeconnectd"
      "pgrep -x kwalletd6 || kwalletd6"
    ];

    config = lib.concatStringsSep "\n" [
      bindsKdl
      settingsKdl
    ];
  };

  xdg.config.files."xdg-desktop-portal/portals.conf".text = ''
    [kde]
    UseIn=niri;

    [gtk]
    UseIn=niri;

    [preferred]
    default=kde;gtk;

    [org.freedesktop.impl.portal.ScreenCast]
    use=kde;

    [org.freedesktop.impl.portal.Screenshot]
    use=kde;

    [org.freedesktop.impl.portal.RemoteDesktop]
    use=kde;

    [org.freedesktop.impl.portal.Inhibit]
    use=kde;

    [org.freedesktop.impl.portal.Settings]
    use=gtk;

    [org.freedesktop.impl.portal.DynamicLauncher]
    use=kde;

    [org.freedesktop.impl.portal.Wallpaper]
    use=kde;

    [org.freedesktop.impl.portal.AppChooser]
    use=gtk;

    [org.freedesktop.impl.portal.Print]
    use=gtk;

    [org.freedesktop.impl.portal.Notification]
    use=gtk;

    [org.freedesktop.impl.portal.Account]
    use=gtk;

    [org.freedesktop.impl.portal.Background]
    use=gtk;

    [org.freedesktop.impl.portal.Email]
    use=gtk;

    [org.freedesktop.impl.portal.OpenURI]
    use=gtk;

    [org.freedesktop.impl.portal.Secret]
    use=gnome-keyring;
  '';
}
