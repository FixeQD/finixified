{ pkgs, spicetify-nix, ... }:
let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.spicetify = {
    enable = true;

    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ] ++ [
      ({
        name = "cat-jam.js";
        src = pkgs.fetchFromGitHub {
          owner = "FixeQD";
          repo = "spicetify-cat-jam-synced-reborn";
          rev = "build";
          hash = "sha256-BgIobG9XbBn6TTb3jtkWjkF0Sba0oYgn61cpkHcxAOo=";
        };
      })
      ({
        name = "dist/djinfo.mjs";
        src = pkgs.fetchFromGitHub {
          owner = "L3-N0X";
          repo = "spicetify-dj-info";
          rev = "main";
          hash = "sha256-WXYhFBKGuwiqAxWLEgP6rzj+82f4Ulm9P7txVssSV/k=";
        };
      })
    ];

    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha"; # TODO: Change that mf
  };
}
