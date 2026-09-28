{ pkgs, config, ... }:
{
  # ── GTK ───────────────────────────────────────────────────────────────────
  gtk = {
    enable = true;

    theme = {
      name = "Breeze-Dark";
      package = pkgs.kdePackages.breeze-gtk;
    };

    gtk4.theme = config.gtk.theme;

    iconTheme = {
      name = "breeze";
      package = pkgs.kdePackages.breeze-icons;
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    font = {
      name = "Noto Sans";
      size = 10;
      package = pkgs.noto-fonts;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-enable-mnemonics = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-mnemonics = true;
    };
  };

  # ── Qt ────────────────────────────────────────────────────────────────────
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style = {
      name = "Breeze";
      package = pkgs.kdePackages.breeze;
    };
  };

  home.file.".config/kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark
    Name=Breeze Dark
    widgetStyle=Breeze

    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop

    [Icons]
    Theme=breeze-dark
  '';

  # ── dconf ──────────────────────────────────────────────────────────────────
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Breeze-Dark";
      icon-theme = "breeze";
      cursor-theme = "Bibata-Modern-Ice";
      cursor-size = 24;
      font-name = "Noto Sans 10";
      document-font-name = "Noto Sans 10";
      monospace-font-name = "JetBrainsMono Nerd Font 10";
      font-antialiasing = "rgba";
      font-hinting = "slight";
      clock-format = "24h";
      enable-animations = true;
      enable-hot-corners = false;
      text-scaling-factor = 1.0;
      show-battery-percentage = true;
    };
  };

  # ── Cursor (system-wide przez X resources) ────────────────────────────────
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # ── Fonty ─────────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
}
