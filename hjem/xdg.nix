{
  config,
  pkgs,
  ...
}:
{
  xdg.mime-apps.default-applications = {
    "text/html" = "helium.desktop";
    "application/xhtml+xml" = "helium.desktop";
    "x-scheme-handler/http" = "helium.desktop";
    "x-scheme-handler/https" = "helium.desktop";
    "x-scheme-handler/about" = "helium.desktop";
    "x-scheme-handler/unknown" = "helium.desktop";
    "inode/directory" = "org.kde.dolphin.desktop";
    "video/mp4" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
    "video/quicktime" = "mpv.desktop";
    "video/mpeg" = "mpv.desktop";
    "audio/mpeg" = "mpv.desktop";
    "audio/flac" = "mpv.desktop";
    "audio/ogg" = "mpv.desktop";
    "audio/wav" = "mpv.desktop";
    "application/ogg" = "mpv.desktop";
    "audio/x-mpegurl" = "mpv.desktop";
    "application/vnd.apple.mpegurl" = "mpv.desktop";
    "image/jpeg" = "qview.desktop";
    "image/png" = "qview.desktop";
    "image/gif" = "qview.desktop";
    "image/webp" = "qview.desktop";
    "image/bmp" = "qview.desktop";
    "image/svg+xml" = "qview.desktop";
    "image/tiff" = "qview.desktop";
    "text/plain" = "dev.zed.Zed.desktop";
    "application/json" = "dev.zed.Zed.desktop";
    "text/x-log" = "dev.zed.Zed.desktop";
    "text/x-patch" = "org.kde.kompare.desktop";
    "text/x-diff" = "org.kde.kompare.desktop";
    "x-scheme-handler/steam" = "steam.desktop";
    "application/zip" = "org.kde.ark.desktop";
    "application/x-zip-compressed" = "org.kde.ark.desktop";
    "application/vnd.rar" = "org.kde.ark.desktop";
    "application/x-rar" = "org.kde.ark.desktop";
    "application/x-rar-compressed" = "org.kde.ark.desktop";
    "application/x-7z-compressed" = "org.kde.ark.desktop";
    "application/x-tar" = "org.kde.ark.desktop";
    "application/gzip" = "org.kde.ark.desktop";
    "application/x-bzip2" = "org.kde.ark.desktop";
    "application/x-xz" = "org.kde.ark.desktop";
  };
  packages = [
    pkgs.desktop-file-utils
    pkgs.shared-mime-info
    pkgs.kdePackages.kservice

    (pkgs.writeShellScriptBin "xdg-bookmarks" ''
      set -eu
      config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
      user_dirs="$config_home/user-dirs.dirs"
      bookmarks="$HOME/.gtk-bookmarks"
      [ -f "$user_dirs" ] || exit 0

      tmp="$(mktemp)"
      trap 'rm -f "$tmp"' EXIT

      while IFS= read -r line; do
        case "$line" in
          XDG_*_DIR=*)
            key="''${line%%=*}"
            [ "$key" = "XDG_DESKTOP_DIR" ] && continue
            value="''${line#*=}"
            value="''${value#\"}"; value="''${value%\"}"
            value="''${value/\$HOME/$HOME}"
            [ -n "$value" ] || continue
            label="''${value##*/}"
            printf 'file://%s %s\n' "$value" "$label" >> "$tmp"
            ;;
        esac
      done < "$user_dirs"

      mv "$tmp" "$bookmarks"
    '')
  ];
}
