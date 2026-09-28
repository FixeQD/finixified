{ config, lib, ... }:
let
  cfg = config.home.niri;

  gradient =
    g: {
      _props = {
        inherit (g) from to angle;
        "in" = g.space;
      };
    };
in
{
  options.home.niri = {
    gaps = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 6;
    };

    border = {
      width = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 2;
      };
      radius = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 10;
      };

      focused = lib.mkOption {
        type = lib.types.attrs;
        default = {
          from = "#ff0000";
          to = "#ff00ff";
          angle = 45;
          space = "oklch longer hue";
        };
        description = ''
          Rainbow gradient for the focused window outline. Rendered as
          `active-gradient from to angle in`, so only the border is tinted and
          the background stays untouched.
        '';
      };

      unfocused = lib.mkOption {
        type = lib.types.attrs;
        default = {
          from = "#7c7f93";
          to = "#45475a";
          angle = 45;
          space = "oklch longer hue";
        };
        description = "Gradient for the outline of unfocused windows.";
      };
    };

    colors = {
      background = lib.mkOption {
        type = lib.types.str;
        default = "#00000000";
        description = "Gap/background color, fully transparent by default.";
      };
    };

    opacity = {
      focused = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
      };
      unfocused = lib.mkOption {
        type = lib.types.float;
        default = 0.8;
      };
    };
  };

  config.home.niri.settings = {
    layout = {
      gaps = cfg.gaps;
      border = {
        width = cfg.border.width;
        "active-gradient" = gradient cfg.border.focused;
        "inactive-gradient" = gradient cfg.border.unfocused;
      };
      focus-ring.off = [ ];
      shadow.on = [ ];
      background-color = cfg.colors.background;
      center-focused-column = "never";
      default-column-display = "normal";
      default-column-width.proportion = 1.0;
    };

    overview.workspace-shadow.off = [ ];
  };
}
