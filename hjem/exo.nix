{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  renderNiriCommand =
    command:
    lib.concatMapStringsSep " " builtins.toJSON (
      lib.filter (arg: arg != "") (lib.splitString " " command)
    );
in
{
  exo = {
    enable = true;
    network.backend = "iwd";

    commands = {
      lock = "hyprlock";
      wallpaperDaemon = "awww-daemon";
    };

    sessionVariables = {
      XCURSOR_SIZE = "24";
      HYPRCURSOR_SIZE = "24";
      HYPRCURSOR_THEME = "Bibata-Modern-Classic";
    };

    tools = {
      pipewire.package = osConfig.programs.pipewire.package;
      wireplumber.package = osConfig.programs.wireplumber.package;
    };

    terminal = {
      name = "ghostty";
      package = pkgs.ghostty;
    };

    fileManager = {
      name = "dolphin";
      package = pkgs.kdePackages.dolphin;
    };

    compositor = {
      enable = true;
      type = "niri";
      autostart = [
        [
          "sh"
          "-c"
          "matugen image ${config.directory}/.wallpaper.jpg --prefer=saturation && ${config.exo.commands.init}"
        ]
        config.exo.commands.wallpaperDaemon
      ];

      niri.bindings = ''
        Mod+Space { spawn ${renderNiriCommand config.exo.commands.launcher}; }
        Mod+l { spawn ${renderNiriCommand config.exo.commands.lock}; }
        Mod+a { spawn ${renderNiriCommand config.exo.commands.quickCenter}; }
        Mod+Shift+Escape { spawn ${renderNiriCommand config.exo.commands.powerMenu}; }
        Mod+Shift+i { spawn ${renderNiriCommand config.exo.commands.settings}; }
      '';
    };

    settings = {
      appearance.wallcolors.wallpaper_path = "${config.directory}/.wallpaper.jpg";
      interface = {
        bar = {
          side = "top";
          density = 3;
          separation = true;
          bar_background = false;
        };
        bar2 = {
          side = "bottom";
          density = 1;
          bar_background = false;
        };
        modules = {
          bar_id = {
            launcher = 1;
            tasks = 1;
            clock = 1;
          };
          visibility = {
            launcher = true;
            tasks = true;
          };
          options = {
            military_time = true;
            workspaces_style = "dots";
          };
        };
      };
    };
  };
}
