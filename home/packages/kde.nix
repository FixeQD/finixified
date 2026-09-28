{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kdePackages.ffmpegthumbs
    kdePackages.filelight
    kdePackages.kdf
    kdePackages.kdialog
    kdePackages.kio-admin
    kdePackages.kompare
    kdePackages.kwallet
    kdePackages.kwayland-integration
    kdePackages.ark
    kdePackages.kservice
  ];
}
