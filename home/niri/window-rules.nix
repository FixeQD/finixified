{ config, ... }:
let
  cfg = config.home.niri;
in
{
  config.home.niri.settings.window-rule = [
    {
      geometry-corner-radius = cfg.border.radius;
      clip-to-geometry = true;
      draw-border-with-background = false;
      background-effect = {
        xray = false;
        blur = true;
      };
    }
    {
      match._props.is-focused = false;
      opacity = cfg.opacity.unfocused;
    }
    {
      match._props.is-focused = true;
      opacity = cfg.opacity.focused;
    }
    {
      match._props.app-id = "^${cfg.terminal.appId}$";
      default-column-width.proportion = 0.5;
    }
    {
      match._props = {
        app-id = "^${cfg.terminal.appId}$";
        is-focused = true;
      };
      opacity = cfg.opacity.focused;
      default-column-width.proportion = 0.5;
    }
    {
      match._props = {
        app-id = "^${cfg.terminal.appId}$";
        title = "^termfilechooser$";
      };
      open-floating = true;
      default-column-width.fixed = 1024;
      default-window-height.fixed = 768;
    }
    {
      match._props.app-id = "^${cfg.browser.appId}$";
      opacity = 1.0;
    }
  ];
}
