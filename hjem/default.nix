{
  imports = [
    ./noctalia-systemd-stub.nix
    ./dconf.nix
    ./packages.nix
    ./programs
    ./gpg-ssh.nix
    ./niri.nix
    ./theme.nix
    ./xdg.nix
  ];

  files.".wallpaper.jpg" = {
    type = "copy";
    source = ./wallpaper.jpg;
  };
}
