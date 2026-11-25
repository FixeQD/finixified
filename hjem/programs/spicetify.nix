{
  inputs,
  config,
  pkgs,
  ...
}:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # `alwaysEnableDevTools` cannot work in the nix flow: the option only lands in the build-time config-xpui.ini
  enableDevtoolsAtLaunch = ''
    spotify_devtools_bnk="''${XDG_CACHE_HOME:-$HOME/.cache}/spotify/offline.bnk"
    if [[ -f "$spotify_devtools_bnk" ]] && ! pgrep -f ".spotify-(wrapped|without-dbus)" > /dev/null; then
      _dt_first="$(LC_ALL=C grep -abo "app-developer" "$spotify_devtools_bnk" | head -n1 | cut -d: -f1)"
      _dt_last="$(LC_ALL=C grep -abo "app-developer" "$spotify_devtools_bnk" | tail -n1 | cut -d: -f1)"
      if [[ -n "$_dt_first" && -n "$_dt_last" && "$_dt_first" -lt "$_dt_last" ]]; then
        printf 2 | dd of="$spotify_devtools_bnk" bs=1 seek=$(( _dt_first + 14 )) conv=notrunc status=none
        printf 2 | dd of="$spotify_devtools_bnk" bs=1 seek=$(( _dt_last + 15 )) conv=notrunc status=none
      fi
    fi
  '';

  lucidTheme = pkgs.runCommand "spicetify-theme-lucid" { } ''
    mkdir -p $out
    cp ${
      pkgs.fetchurl {
        url = "https://spicetify-lucid.sanooj.uk/spice/user.css";
        hash = "sha256-2cdRiVcd7x3vcsuCsfTekhSRvez+HpZNq8cIcNPYa7Q=";
      }
    } $out/user.css
    cp ${
      pkgs.fetchurl {
        url = "https://spicetify-lucid.sanooj.uk/spice/color.ini";
        hash = "sha256-iVxVBO1HvI0trHsw7GC3sEGvyOzHHTdkRvpqyfqlcVk=";
      }
    } $out/color.ini
    cp ${
      pkgs.fetchurl {
        url = "https://spicetify-lucid.sanooj.uk/spice/theme.js";
        hash = "sha256-+GZJ+dqCG6wbKo0WMrZrDSplBNpH7r3LhMMa4JSYxRE=";
      }
    } $out/theme.js
  '';

  spotify = pkgs.spotify.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      pkgs.libayatana-appindicator
      pkgs.libayatana-indicator
    ];

    postFixup = (old.postFixup or "") + ''
      # Reuse the desktop session bus so MPRIS is visible to playerctl and panels.
      mv "$out/share/spotify/spotify" "$out/share/spotify/.spotify-without-dbus"
      makeShellWrapper ${pkgs.dbus}/bin/dbus-launch "$out/share/spotify/spotify" \
        --run '
          spotify_dbus_machine_id="$(cat /etc/machine-id)"
          ${enableDevtoolsAtLaunch}
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

  spotifyPath = "${pkgs.lib.head config.programs.spicetify.createdPackages}/share/spotify";
in
{
  # `spicetify ...` CLI runs need a valid spotify_path
  files.".config/spicetify/config-xpui.ini" = {
    type = "copy";
    source = pkgs.writeText "spicetify-config-xpui" ''
      [Setting]
      spotify_path           = ${spotifyPath}
      always_enable_devtools = 1
    '';
  };

  programs.spicetify = {
    enable = true;

    spotifyPackage = pkgs.lib.hiPrio spotify;

    enabledExtensions =
      with spicePkgs.extensions;
      [
        adblock
        hidePodcasts
        shuffle
      ]
      ++ [
        {
          name = "cat-jam.js";
          src = pkgs.fetchFromGitHub {
            owner = "FixeQD";
            repo = "spicetify-cat-jam-synced-reborn";
            rev = "build";
            hash = "sha256-VnPEeMTyAxZF+KhckSifpwcJKk16TZGlZlW4KrmmPMQ=";
          };
        }
        {
          name = "djinfo.mjs";
          src = "${
            pkgs.fetchFromGitHub {
              owner = "L3-N0X";
              repo = "spicetify-dj-info";
              rev = "main";
              hash = "sha256-B5/dE8GVsPbDSCGx0s8O2CMpOHLu/WPWIv1AAE8sObs=";
            }
          }/dist";
        }
        {
          name = "spicy-lyrics.mjs";
          src = "${
            pkgs.fetchFromGitHub {
              owner = "Spikerko";
              repo = "spicy-lyrics";
              rev = "main";
              hash = "sha256-AtbSWgJyj8oJbUzCP5I94fQK28et/PW/uO0rMKyxB6E=";
            }
          }/builds";
        }
        {
          name = "speedify.js";
          src = "${
            pkgs.fetchFromGitHub {
              owner = "ssatwik975";
              repo = "Speedify";
              rev = "main";
              hash = "sha256-Kf+mR41NfX+yOEQCnDFUjHRPcJZHvPFXBUFg6BBuYXA=";
            }
          }/dist";
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
