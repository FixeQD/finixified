{ config, lib, ... }:
let
  cfg = config.home.niri;
in
{
  options.home.niri.keyboard.layout = lib.mkOption {
    type = lib.types.str;
    default = "pl";
  };

  config.home.niri.settings.input = {
    keyboard.xkb.layout = cfg.keyboard.layout;
    focus-follows-mouse._props = { };
    touchpad = {
      natural-scroll = [ ];
      dwt = [ ];
      tap = [ ];
      middle-emulation = [ ];
      scroll-factor = 1.0;
    };
  };
}
