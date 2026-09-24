{
  description = "finix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    finix.url = "github:finix-community/finix";
    community-modules.url = "github:finix-community/community-modules";

    efistubmgr = {
      url = "github:finix-community/efistubmgr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord.url = "github:4evy/nixcord";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      finix,
      community-modules,
      disko,
      sops-nix,
      zen-browser,
      spicetify-nix,
      noctalia,
      nixcord,
      efistubmgr,
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
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              sops-nix.overlays.default
              (import ./pkgs)
              (final: prev: {
                efistubmgr = efistubmgr.packages.${system}.default;
              })
            ];
          };
          hostConfig = (import host) {
            inherit pkgs nixpkgs finix community-modules disko zen-browser spicetify-nix noctalia nixcord;
          };
        in
        finix.lib.finixSystem {
          inherit (pkgs) lib;
          inherit (hostConfig) specialArgs;
          modules = [
            { nixpkgs.pkgs = nixpkgs.lib.mkDefault pkgs; }
          ]
          ++ hostConfig.modules
          ++ extraModules;
        };

      hostConfigurations = {
        wifi-chan = mkHost { host = ./hosts/wifi-chan/default.nix; };
        gownobook = mkHost { host = ./hosts/gownobook/default.nix; };
      };

      mkInstallApp =
        { config, resume ? false }:
        let
          hostname = config.networking.hostName;
          system = config.nixpkgs.pkgs.stdenv.hostPlatform.system;
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          type = "app";
          program = toString (
            pkgs.writeShellScript "${if resume then "resume-" else ""}install-${hostname}" ''
              export DISKO_BIN="${disko.packages.${system}.disko}/bin/disko"
              export SBCTL_BIN="${pkgs.sbctl}/bin/sbctl"
              export MKPASSWD_BIN="${pkgs.mkpasswd}/bin/mkpasswd"
              export FLAKE_HOST="${hostname}"
              export PRIMARY_USER="${config.modules.user.name}"
              export REQUIRE_SOPS="${if config.modules.installer.requireSops then "true" else "false"}"
              export RESUME_INSTALL="${if resume then "true" else "false"}"
              ${if resume then ''export DISKO_MODE="mount"'' else ""}
              source ${./install.sh}
            ''
          );
        };
    in
    {
      nixosConfigurations = hostConfigurations;

      apps.x86_64-linux.install-wifi-chan = mkInstallApp { config = hostConfigurations.wifi-chan.config; };
      apps.x86_64-linux.resume-install-wifi-chan = mkInstallApp { config = hostConfigurations.wifi-chan.config; resume = true; };

      apps.x86_64-linux.install-gownobook = mkInstallApp { config = hostConfigurations.gownobook.config; };
      apps.x86_64-linux.resume-install-gownobook = mkInstallApp { config = hostConfigurations.gownobook.config; resume = true; };
    };
}
