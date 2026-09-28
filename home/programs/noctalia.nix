{ ... }:
{
  programs.noctalia = {
    enable = true;

    settings = {
      theme = {
        mode = "dark";
      };

      wallpaper = {
        enabled = true;
        default.path = "/home/fixeq/.wallpaper.jpg";
      };
    };
  };
}
