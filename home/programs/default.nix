{ pkgs, ... }:
{
  imports = [
    ./fastfetch.nix
    ./gh.nix
    ./ghostty.nix
    ./nixcord.nix
    ./noctalia.nix
    ./spicetify.nix
    ./starship.nix
    ./zed.nix
  ];

  programs.nushell = {
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

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase        = false;
      user.name          = "Paweł";
      user.email         = "github@fixeq.qzz.io";
    };
  };
}
