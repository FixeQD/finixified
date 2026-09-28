{ config, pkgs, zen-browser, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "x-terminal-emulator" ''
      exec ${pkgs.ghostty}/bin/ghostty "$@"
    '')
    (pkgs.writeShellScriptBin "www-browser" ''
      exec ${zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/zen "$@"
    '')
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html"                     = "zen.desktop";
      "application/xhtml+xml"         = "zen.desktop";
      "x-scheme-handler/http"         = "zen.desktop";
      "x-scheme-handler/https"        = "zen.desktop";
      "x-scheme-handler/about"        = "zen.desktop";
      "x-scheme-handler/unknown"      = "zen.desktop";

      "inode/directory"               = "org.kde.dolphin.desktop";

      "video/mp4"                     = "mpv.desktop";
      "video/x-matroska"              = "mpv.desktop";
      "video/webm"                    = "mpv.desktop";
      "video/x-msvideo"               = "mpv.desktop";
      "video/quicktime"               = "mpv.desktop";
      "video/mpeg"                    = "mpv.desktop";
      "audio/mpeg"                    = "mpv.desktop";
      "audio/flac"                    = "mpv.desktop";
      "audio/ogg"                     = "mpv.desktop";
      "audio/wav"                     = "mpv.desktop";
      "application/ogg"               = "mpv.desktop";
      "audio/x-mpegurl"               = "mpv.desktop";
      "application/vnd.apple.mpegurl" = "mpv.desktop";

      "image/jpeg"                    = "qview.desktop";
      "image/png"                     = "qview.desktop";
      "image/gif"                     = "qview.desktop";
      "image/webp"                    = "qview.desktop";
      "image/bmp"                     = "qview.desktop";
      "image/svg+xml"                 = "qview.desktop";
      "image/tiff"                    = "qview.desktop";

      "text/plain"                    = "dev.zed.Zed.desktop";
      "application/json"              = "dev.zed.Zed.desktop";
      "text/x-log"                    = "dev.zed.Zed.desktop";

      "text/x-patch"                  = "org.kde.kompare.desktop";
      "text/x-diff"                   = "org.kde.kompare.desktop";

      "x-scheme-handler/steam"        = "steam.desktop";

      "application/zip"               = "org.kde.ark.desktop";
      "application/x-zip-compressed"  = "org.kde.ark.desktop";
      "application/vnd.rar"           = "org.kde.ark.desktop";
      "application/x-rar"             = "org.kde.ark.desktop";
      "application/x-rar-compressed"  = "org.kde.ark.desktop";
      "application/x-7z-compressed"   = "org.kde.ark.desktop";
      "application/x-tar"             = "org.kde.ark.desktop";
      "application/gzip"              = "org.kde.ark.desktop";
      "application/x-bzip2"           = "org.kde.ark.desktop";
      "application/x-xz"              = "org.kde.ark.desktop";
    };
  };

  home.activation.updateDesktopDb = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.desktop-file-utils}/bin:${pkgs.shared-mime-info}/bin:${pkgs.kdePackages.kservice}/bin:$PATH"
    mkdir -p "$HOME/.local/share/applications" "$HOME/.local/share/mime"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
    kbuildsycoca6 --noincremental 2>/dev/null || true
  '';
}
