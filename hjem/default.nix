{
  imports = [
    ./exo.nix
    ./packages.nix
    ./programs
    ./gpg.nix
    ./niri.nix
    ./theme.nix
    ./xdg.nix
  ];

  files.".wallpaper.jpg" = {
    type = "copy";
    source = ./wallpaper.jpg;
  };
}
