{
  inputs,
  pkgs,
  ...
}:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  lucidTheme = pkgs.runCommand "spicetify-theme-lucid" { } ''
    mkdir -p $out
    cp ${pkgs.fetchurl {
      url = "https://spicetify-lucid.sanooj.uk/spice/user.css";
      hash = "sha256-70N9VgIrroy+wDzmY2i5hgddOOVBtP4zyVT3mAB1qbo=";
    }} $out/user.css
    cp ${pkgs.fetchurl {
      url = "https://spicetify-lucid.sanooj.uk/spice/color.ini";
      hash = "sha256-iVxVBO1HvI0trHsw7GC3sEGvyOzHHTdkRvpqyfqlcVk=";
    }} $out/color.ini
    cp ${pkgs.fetchurl {
      url = "https://spicetify-lucid.sanooj.uk/spice/theme.js";
      hash = "sha256-+GZJ+dqCG6wbKo0WMrZrDSplBNpH7r3LhMMa4JSYxRE=";
    }} $out/theme.js
  '';

  spotify = pkgs.spotify.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [
      pkgs.libayatana-appindicator
      pkgs.libayatana-indicator
    ];

    postFixup = (old.postFixup or "") + ''
      # Reuse the desktop session bus so MPRIS is visible to playerctl and panels.
      mv "$out/share/spotify/spotify" "$out/share/spotify/.spotify-without-dbus"
      makeShellWrapper ${pkgs.dbus}/bin/dbus-launch "$out/share/spotify/spotify" \
        --run '
          spotify_dbus_machine_id="$(cat /etc/machine-id)"
          case "''${XDG_SESSION_TYPE:-}" in
            wayland) spotify_ozone_platform=wayland ;;
            x11) spotify_ozone_platform=x11 ;;
            *)
              if [[ -n "''${WAYLAND_DISPLAY:-}" ]]; then
                spotify_ozone_platform=wayland
              else
                spotify_ozone_platform=x11
              fi
              ;;
          esac
          # The nixpkgs launcher otherwise removes DISPLAY when this is set.
          if [[ "$spotify_ozone_platform" == x11 ]]; then
            unset NIXOS_OZONE_WL
          fi
        ' \
        --add-flags "--autolaunch=\$spotify_dbus_machine_id --exit-with-session $out/share/spotify/.spotify-without-dbus --ozone-platform=\$spotify_ozone_platform"
    '';
  });
in
{
  programs.spicetify = {
    enable = true;

    spotifyPackage = pkgs.lib.hiPrio spotify;

    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ] ++ [
      {
        name = "cat-jam.js";
        src = pkgs.fetchFromGitHub {
          owner = "FixeQD";
          repo = "spicetify-cat-jam-synced-reborn";
          rev = "build";
          hash = "sha256-BgIobG9XbBn6TTb3jtkWjkF0Sba0oYgn61cpkHcxAOo=";
        };
      }
      {
        name = "djinfo.mjs";
        src = "${pkgs.fetchFromGitHub {
          owner = "L3-N0X";
          repo = "spicetify-dj-info";
          rev = "main";
          hash = "sha256-rg/SfzIIkrSle2c6xhHfSUyBfrKecq6CY+9HXRI78xA=";
        }}/dist";
      }
      {
        name = "spicy-lyrics.mjs";
        src = "${pkgs.fetchFromGitHub {
          owner = "Spikerko";
          repo = "spicy-lyrics";
          rev = "main";
          hash = "sha256-OlzNKuTB2jeWXEgMbpBvhv/GKTGG1FmjhtusUOkFBOg=";
        }}/builds";
      }
      {
        name = "speedify.js";
        src = "${pkgs.fetchFromGitHub {
          owner = "ssatwik975";
          repo = "Speedify";
          rev = "main";
          hash = "sha256-Kf+mR41NfX+yOEQCnDFUjHRPcJZHvPFXBUFg6BBuYXA=";
        }}/dist";
      }
      {
        name = "cacheCleaner.js";
        src = pkgs.fetchFromGitHub {
          owner = "kyrie25";
          repo = "Spicetify-Cache-Cleaner";
          rev = "main";
          hash = "sha256-VuBbW4xYpB2QbSsNjR1an05WMXhLU9rv9moHw/DgCgk=";
        };
      }
      {
        name = "clean-links.js";
        src = pkgs.fetchFromGitHub {
          owner = "Borfak";
          repo = "spicetify-clean-links";
          rev = "main";
          hash = "sha256-TUe+MKXfrIEaQKhIFbwIVdHOKw7wG5vKQMeUeVUEHKY=";
        };
      }
    ];

    theme = {
      name = "Lucid";
      src = lucidTheme;
      injectCss = true;
      injectThemeJs = true;
      replaceColors = true;
      homeConfig = true;
      overwriteAssets = false;
      additionalCss = "";
    };

    colorScheme = "use-lucid";
  };
}
