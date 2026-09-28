{
  config,
  ...
}:
{
  programs.noctalia = {
    enable = true;
    settings = {
      theme = {
        mode = "dark";
      };
      wallpaper = {
        enabled = true;
        default.path = "${config.directory}/.wallpaper.jpg";
      };
    };
  };
}
