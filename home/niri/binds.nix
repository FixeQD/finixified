{ config, lib, ... }:
let
  cfg = config.home.niri;

  mouseBinds = {
    "Mod+WheelScrollDown" = {
      focus-column-right = [ ];
    };
    "Mod+WheelScrollUp" = {
      focus-column-left = [ ];
    };
    "Mod+Ctrl+WheelScrollDown" = {
      focus-workspace-down = [ ];
    };
    "Mod+Ctrl+WheelScrollUp" = {
      focus-workspace-up = [ ];
    };
    "Mod+Shift+WheelScrollDown" = {
      move-column-right = [ ];
    };
    "Mod+Shift+WheelScrollUp" = {
      move-column-left = [ ];
    };
    "Mod+MouseMiddle" = {
      toggle-overview = [ ];
    };
  };

  windowBinds = {
    "Mod+o" = {
      toggle-overview = [ ];
    };
    "Mod+q" = {
      close-window = [ ];
    };
    "Mod+v" = {
      toggle-window-floating = [ ];
    };
    "Mod+j" = {
      focus-window-down = [ ];
    };
    "Mod+k" = {
      focus-window-up = [ ];
    };
    "Mod+h" = {
      focus-column-left-or-last = [ ];
    };
    "Mod+l" = {
      focus-column-right-or-first = [ ];
    };
    "Mod+Shift+j" = {
      move-window-down = [ ];
    };
    "Mod+Shift+k" = {
      move-window-up = [ ];
    };
    "Mod+Shift+h" = {
      move-column-left-or-to-monitor-left = [ ];
    };
    "Mod+Shift+l" = {
      move-column-right-or-to-monitor-right = [ ];
    };
    "Mod+Comma" = {
      consume-window-into-column = [ ];
    };
    "Mod+Period" = {
      expel-window-from-column = [ ];
    };
    "Mod+f" = {
      maximize-column = [ ];
    };
    "Mod+Shift+f" = {
      fullscreen-window = [ ];
    };
  };

  sizeBinds = {
    "Mod+Control+l" = {
      set-column-width = "+10%";
    };
    "Mod+Control+h" = {
      set-column-width = "-10%";
    };
    "Mod+Control+k" = {
      set-window-height = "+10%";
    };
    "Mod+Control+j" = {
      set-window-height = "-10%";
    };
  };

  screenshotBinds = {
    "Print" = {
      screenshot = [ ];
    };
    "Shift+Print" = {
      screenshot-screen = [ ];
    };
    "Ctrl+Print" = {
      screenshot-window = [ ];
    };
  };

  workspaceBinds =
    lib.listToAttrs (lib.map (n: {
      name = "Mod+${toString n}";
      value = {
        focus-workspace = n;
      };
    }) (lib.range 1 9))
    // lib.listToAttrs (lib.map (n: {
      name = "Mod+Shift+${toString n}";
      value = {
        move-window-to-workspace = n;
      };
    }) (lib.range 1 9));

  spawnBinds = {
    "Mod+Return" = {
      spawn = cfg.terminal.command;
    };
    "Mod+e" = {
      spawn = cfg.terminal.command ++ [ "-e" "yazi" ];
    };
    "Mod+b" = {
      spawn  = cfg.browser.command;
    };
    "Mod+c" = {
      spawn = cfg.editor.command;
    };
  };

  miscBinds = {
    "Mod+Escape" = {
      quit = [ ];
    };
  };
in
{
  config.home.niri.settings.binds =
    windowBinds
    // sizeBinds
    // screenshotBinds
    // workspaceBinds
    // spawnBinds
    // miscBinds
    // mouseBinds
    // cfg.extraBinds;
}
