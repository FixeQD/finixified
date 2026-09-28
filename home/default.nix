{ username, ... }:
{
  imports = [
    ./niri
    ./packages.nix
    ./programs
    ./system
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion  = "26.05";
    enableNixpkgsReleaseCheck = false;

    file.".wallpaper.jpg" = {
      source = ./wallpaper.jpg;
    };
  };

  xdg.enable          = true;
  xdg.userDirs.enable = true;
  xdg.userDirs.setSessionVariables = true;
}
