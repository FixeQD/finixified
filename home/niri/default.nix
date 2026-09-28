{
  niri-nix,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home.niri;

  settings = {
    environment = {
      _JAVA_AWT_WM_NONREPARENTING = "1";
      AWT_TOOLKIT = "MToolkit";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland";
      DISPLAY = ":0";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      SDL_VIDEODRIVER = "wayland";
      QT_QPA_PLATFORMTHEME = "gtk4";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NVD_BACKEND = "direct";
    };

    prefer-no-csd = [ ];

    spawn-at-startup = map (cmd: {
      _args = [
        "sh"
        "-c"
        cmd
      ];
    }) cfg.autoStart;

    xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite}";
  };
in
{
  imports = [
    ./binds.nix
    ./cursor.nix
    ./input.nix
    ./layout.nix
    ./portal.nix
    ./window-rules.nix
  ];

  options.home.niri = {
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Raw niri settings, merged from the sibling modules.";
    };

    terminal = {
      command = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "ghostty" ];
      };
      appId = lib.mkOption {
        type = lib.types.str;
        default = "com.mitchellh.ghostty";
      };
    };

    browser = {
      command = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "zen" ];
      };
      appId = lib.mkOption {
        type = lib.types.str;
        default = "zen";
      };
    };

    editor = {
      command = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "zeditor" ];
      };
      appId = lib.mkOption {
        type = lib.types.str;
        default = "dev.zed.Zed";
      };
    };

    autoStart = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "noctalia"
        "polkit-kde-authentication-agent-1"
        "pgrep -x kdeconnectd || kdeconnectd"
        "pgrep -x kwalletd6 || kwalletd6"
      ];
      description = "Commands run at niri startup, wrapped with `sh -c`.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = ''
        layer-rule {
          match namespace=r#"^noctalia-wallpaper.*"#
          place-within-backdrop true
        }
      '';
      description = "Raw KDL appended to the generated config.";
    };

    extraBinds = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Additional key bindings, same shape as the generated ones.";
    };
  };

  config = {
    xdg.configFile."niri/config.kdl".source = pkgs.writeTextFile {
      name = "niri-config.kdl";
      text =
        niri-nix.lib.mkNiriKDL (settings // config.home.niri.settings)
        + "\n"
        + cfg.extraConfig;
    };
  };
}
