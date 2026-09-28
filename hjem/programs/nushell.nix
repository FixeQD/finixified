{
  pkgs,
  ...
}:
{
  rum.programs.nushell = {
    enable = true;
    settings.show_banner = false;
    plugins = with pkgs.nushellPlugins; [
      desktop_notifications
      formats
      gstat
    ];
    extraConfig = ''
      $env.GPG_TTY = (tty | into string)
      ^fastfetch
    '';
  };
}
