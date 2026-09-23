{ username, ... }:
{
  imports = [
    ./packages.nix
    ./programs.nix
    ./theme.nix
    ./dconf-extra.nix
    ./secrets-keys.nix
    ./xdg-mime.nix
    ./zed.nix
    ./dotfiles.nix
    ./spicetify.nix
    ./noctalia.nix
    ./nixcord.nix
    ./gh.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion  = "26.05";
    enableNixpkgsReleaseCheck = false;
  };

  xdg.enable          = true;
  xdg.userDirs.enable = true;
  xdg.userDirs.setSessionVariables = true;
}
