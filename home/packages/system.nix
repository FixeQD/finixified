{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gparted
    ntfs3g
    wireguard-tools
    spicetify-cli
    modprobed-db
    cpupower-gui
    yazi
  ];
}
