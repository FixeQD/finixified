{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = config.directory;

  toGvariant =
    v:
    if builtins.isBool v then
      if v then "true" else "false"
    else if builtins.isInt v then
      "int32 ${toString v}"
    else if builtins.isFloat v then
      "double ${toString v}"
    else if builtins.isList v then
      (if builtins.all builtins.isString v then "@as " else "")
      + "[ "
      + lib.concatStringsSep ", " (map toGvariant v)
      + " ]"
    else
      "'" + lib.replaceStrings [ "'" ] [ "\\'" ] v + "'";

  section =
    path:
    let
      body = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: "${name}=${toGvariant value}") dconfSettings.${path}
      );
    in
    "[${path}]\n${body}\n";

  dconfSettings = {
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
      show-hidden = false;
      date-format = "regular";
      view-type = "list";
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      sort-directories-first = true;
      show-hidden = false;
    };

    "org/gnome/desktop/sound" = {
      event-sounds = false;
      theme-name = "freedesktop";
    };

    "org/gnome/desktop/privacy" = {
      remember-recent-files = true;
      recent-files-max-age = 30;
      report-technical-problems = false;
    };

    "org/blueman/general" = {
      symbolic-status-icons = true;
    };

    "org/blueman/plugins/powermanager" = {
      auto-power-on = true;
    };

    "org/blueman/transfer" = {
      shared-path = "${home}/Downloads";
    };

    "org/gnome/system/proxy" = {
      mode = "none";
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Breeze-Dark";
      icon-theme = "breeze";
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 24;
      font-name = "Noto Sans 10";
      monospace-font-name = "JetBrainsMono Nerd Font 10";
      font-antialiasing = "rgba";
      font-hinting = "slight";
      enable-animations = true;
      clock-format = "24h";
    };
  };

  keyfile = pkgs.runCommand "dconf-keys" { } ''
    mkdir -p $out
    cat >$out/dconf <<'EOF'
    ${lib.concatStrings (lib.map section (lib.attrNames dconfSettings))}
    EOF
  '';

  database = pkgs.runCommand "dconf-user" { nativeBuildInputs = [ pkgs.dconf ]; } ''
    ${lib.getExe pkgs.dconf} compile $out ${keyfile}
  '';
in
{
  files.".config/dconf/user" = {
    type = "copy";
    source = database;
  };

  packages = [ pkgs.dconf ];
}
