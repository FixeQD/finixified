{
  pkgs,
  ...
}:
{
  rum.misc.gtk = {
    enable = true;

    packages = [
      pkgs.kdePackages.breeze-gtk
      pkgs.noto-fonts
    ];

    # Generator hjem-rum doklada prefiks `gtk-`, a GTK zna tylko
    # `gtk-cursor-theme-name` / `gtk-icon-theme-name`. `gtk-cursor-size` nie
    # istnieje w GTK -- rozmiar kursora idzie przez `XCURSOR_SIZE` i
    # `GTK_CURSOR_SIZE`.
    settings = {
      theme-name = "Breeze-Dark";
      icon-theme-name = "breeze";
      cursor-theme-name = "Bibata-Modern-Classic";
      font-name = "Noto Sans 10";
      application-prefer-dark-theme = true;
      decoration-layout = "icon:minimize,maximize,close";
      enable-animations = true;
      enable-mnemonics = true;
    };
  };

  xdg.config.files."kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark
    Name=Breeze Dark
    widgetStyle=Breeze

    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop

    [Icons]
    Theme=breeze-dark
  '';

  environment.sessionVariables = {
    GTK_CURSOR_THEME = "Bibata-Modern-Classic";
    GTK_CURSOR_SIZE = "24";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji
    kdePackages.breeze
  ];
}
