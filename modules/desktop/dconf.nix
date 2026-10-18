{
  config,
  lib,
  finix,
  ...
}:
with lib;
let
  cfg = config.modules.dconf;

  homeDir = attrsets.attrByPath [ config.modules.user.name "home" ] "/home/${config.modules.user.name}" config.users.users;

  mkInt32 = lib.gvariant.mkInt32;
in
{
  imports = [ finix.nixosModules.dconf ];

  options.modules.dconf.enable = mkEnableOption "dconf settings, keyfiles and profiles";

  config = mkIf cfg.enable {
    programs.dconf = {
      enable = true;

      profiles.user.databases = [
        {
          settings = {
            "org/gtk/settings/file-chooser" = {
              sort-directories-first = true;
              show-hidden = false;
              date-format = "regular";
              view-type = "list";
            };

            "org/gtk/gtk4/settings/file-chooser" = {
              sort-directories-first = true;
              show-hidden = false;
            };

            "org/gnome/desktop/sound" = {
              event-sounds = false;
              theme-name = "freedesktop";
            };

            "org/gnome/desktop/privacy" = {
              remember-recent-files = true;
              recent-files-max-age = mkInt32 30;
              report-technical-problems = false;
            };

            "org/blueman/general" = {
              symbolic-status-icons = true;
            };

            "org/blueman/plugins/powermanager" = {
              auto-power-on = true;
            };

            "org/blueman/transfer" = {
              shared-path = "${homeDir}/Downloads";
            };

            "org/gnome/system/proxy" = {
              mode = "none";
            };

            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-theme = "Breeze-Dark";
              icon-theme = "breeze";
              cursor-theme = "Bibata-Modern-Classic";
              cursor-size = mkInt32 24;
              font-name = "Noto Sans 10";
              monospace-font-name = "JetBrainsMono Nerd Font 10";
              font-antialiasing = "rgba";
              font-hinting = "slight";
              enable-animations = true;
              clock-format = "24h";
            };
          };
        }
      ];
    };
  };
}