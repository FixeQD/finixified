{ config, lib, ... }:
let
  cfg = config.home.niri;
in
{
  options.home.niri.cursor = {
    theme = lib.mkOption {
      type = lib.types.str;
      default = "Bibata-Modern-Classic";
    };

    size = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 24;
    };
  };

  config.home.niri.settings.cursor = {
    xcursor-theme = cfg.cursor.theme;
    xcursor-size = cfg.cursor.size;
    hide-when-typing = [ ];
    hide-after-inactive-ms = 3000;
  };
}
