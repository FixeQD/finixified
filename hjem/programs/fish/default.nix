{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  templates = import ./template.nix { inherit inputs lib pkgs; };
in
{
  packages = [
    pkgs.jq
    inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-db
  ];

  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "zed --wait";
    NH_FLAKE = templates.flakePath;
    NIX_FLAKE = templates.flakePath;
  };

  rum.programs.direnv = {
    enable = true;
    integrations = {
      fish.enable = true;
      nix-direnv.enable = true;
    };
  };

  rum.programs.nix-your-shell = {
    enable = true;
    integrations.fish.enable = true;
  };

  rum.programs.fish = {
    enable = true;
    abbrs = {
      ll = "eza -la --git";
      l = "eza -l --git";
      t = "eza --tree";
      c = "bat --paging=never";
      gst = "git status";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate -20";
    };
    aliases = {
      ex = "exit";
      vi = "nvim";
      cat = "bat --paging=never";
      fd = "fd --type f";
      find = "fd";
      top = "btop";
    };
    functions = templates.functions;
    earlyConfigFiles = templates.confFiles;
    config = templates.configFile;
  };
}
