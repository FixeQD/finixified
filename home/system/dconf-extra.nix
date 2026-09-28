{ ... }:
{
  dconf.settings = {
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
      recent-files-max-age = 30;
      report-technical-problems = false;
    };

    "org/blueman/general" = {
      symbolic-status-icons = true;
    };

    "org/blueman/plugins/powermanager" = {
      auto-power-on = true;
    };

    "org/blueman/transfer" = {
      shared-path = "/home/fixeq/Downloads";
    };

    "org/gnome/system/proxy" = {
      mode = "none";
    };
  };
}
