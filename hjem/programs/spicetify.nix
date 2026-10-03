{
  inputs,
  pkgs,
  ...
}:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  spotify = pkgs.spotify.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [
      pkgs.libayatana-appindicator
      pkgs.libayatana-indicator
    ];

    postFixup = (old.postFixup or "") + ''
      # Keep the library wrapper inside a dedicated D-Bus session.
      mv "$out/share/spotify/spotify" "$out/share/spotify/.spotify-without-dbus"
      makeShellWrapper ${pkgs.dbus}/bin/dbus-run-session "$out/share/spotify/spotify" \
        --run '
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
        --add-flags "$out/share/spotify/.spotify-without-dbus --ozone-platform=\$spotify_ozone_platform"
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
        name = "dist/djinfo.mjs";
        src = pkgs.fetchFromGitHub {
          owner = "L3-N0X";
          repo = "spicetify-dj-info";
          rev = "main";
          hash = "sha256-rg/SfzIIkrSle2c6xhHfSUyBfrKecq6CY+9HXRI78xA=";
        };
      }
    ];

    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha"; # TODO: Change that mf
  };
}
