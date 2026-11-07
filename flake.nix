{
  description = "finix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    finix.url = "github:finix-community/finix";
    community-modules.url = "github:finix-community/community-modules";

    nixcord.url = "github:4evy/nixcord";
    nix-index-database.url = "github:nix-community/nix-index-database";

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:FixeQD/sops-nix/feat/non-systemd-activation";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem-rum = {
      url = "github:snugnug/hjem-rum";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hjem.follows = "hjem";
    };

    helium = {
      url = "github:AlvaroParker/helium-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    exo = {
      url = "github:FixeQD/Exo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      finix,
      community-modules,
      nixcord,
      disko,
      sops-nix,
      helium,
      ...
    }:
    let
      mkHost =
        {
          host,
          system ? "x86_64-linux",
          extraModules ? [ ],
        }:
        let
          flakeDir = "/etc/finix";

          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
            overlays = [
              sops-nix.overlays.default
            ];
          };
          hostConfig = (import host) {
            inherit
              pkgs
              nixpkgs
              inputs
              disko
              community-modules
              finix
              nixcord
              flakeDir
              ;
          };
        in
        finix.lib.finixSystem {
          inherit (pkgs) lib;
          specialArgs = (hostConfig.specialArgs or { }) // {
            inherit sops-nix;
          };
          modules = [
            { nixpkgs.pkgs = nixpkgs.lib.mkDefault pkgs; }
            (
              { config, ... }:
              let
                user = config.modules.user.name;
              in
              {
                system.activation.scripts.ensure-flake-dir = {
                  deps = [ "users" ];
                  text = ''
                    install -d -o ${user} -g ${config.users.users.${user}.group} -m 0775 ${flakeDir}
                  '';
                };
              }
            )
          ]
          ++ hostConfig.modules
          ++ extraModules;
        };

      hostConfigurations = {
        wifi-chan = mkHost { host = ./hosts/wifi-chan/default.nix; };
        gownobook = mkHost { host = ./hosts/gownobook/default.nix; };
      };

      mkInstallApp =
        {
          config,
          resume ? false,
        }:
        let
          installer = if resume then config.system.build.resumeInstaller else config.system.build.installer;
        in
        {
          type = "app";
          program = nixpkgs.lib.getExe installer;
          meta.description = installer.meta.description;
        };
    in
    {
      nixosConfigurations = hostConfigurations;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;

      apps.x86_64-linux = nixpkgs.lib.concatMapAttrs (name: host: {
        "install-${name}" = mkInstallApp { inherit (host) config; };
        "resume-install-${name}" = mkInstallApp {
          inherit (host) config;
          resume = true;
        };
      }) hostConfigurations;
    };
}
