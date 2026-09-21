{
  description = "finix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    finix.url = "github:FixeQD/finix/0dbbc77498386cf444affe9d4fc710d43e23fcd8";
    community-modules.url = "github:finix-community/community-modules";

    efistubmgr = {
      url = "github:finix-community/efistubmgr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord.url = "github:4evy/nixcord";

    nyth = {
      url = "github:FixeQD/nyth";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      nyth,
      noctalia,
      nixcord,
      efistubmgr,
      ...
    }:
    let
      mkHost =
        {
          hostname,
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
        in
        finix.lib.finixSystem {
          inherit (pkgs) lib;
          modules = [
            { nixpkgs.pkgs = nixpkgs.lib.mkDefault pkgs; }
            { _module.args = { inherit zen-browser spicetify-nix nyth noctalia nixcord; }; }
            disko.nixosModules.disko
            community-modules.nixosModules.home-manager
            community-modules.nixosModules.tailscale
            finix.nixosModules.pipewire
            finix.nixosModules.wireplumber
            community-modules.nixosModules.nix-ld
            community-modules.nixosModules.openrgb
            community-modules.nixosModules.fastfetch
            ./modules/sops
            finix.nixosModules.bluetooth
            finix.nixosModules.docker
            finix.nixosModules.getty
            finix.nixosModules.openssh
            finix.nixosModules.hyprland
            finix.nixosModules.niri
            community-modules.nixosModules.bootchart
            finix.nixosModules.xwayland-satellite
            finix.nixosModules.nix-daemon
            finix.nixosModules.sudo
            finix.nixosModules.sysklogd
            finix.nixosModules.iwd
            finix.nixosModules.dhcpcd
            finix.nixosModules.sddm
            finix.nixosModules.zzz
            finix.nixosModules.brightnessctl
            finix.nixosModules.fwupd
            finix.nixosModules.upower
            ./hosts/${hostname}/default.nix
          ]
          ++ extraModules;
        };

      mkInstallApp =
        { hostname, resume ? false, requireSops ? true }:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          type = "app";
          program = toString (
            pkgs.writeShellScript "${if resume then "resume-" else ""}install-${hostname}" ''
              export DISKO_BIN="${disko.packages.x86_64-linux.disko}/bin/disko"
              export SBCTL_BIN="${pkgs.sbctl}/bin/sbctl"
              export MKPASSWD_BIN="${pkgs.mkpasswd}/bin/mkpasswd"
              export FLAKE_HOST="${hostname}"
              export PRIMARY_USER="fixeq"
              export REQUIRE_SOPS="${if requireSops then "true" else "false"}"
              ${if resume then ''export DISKO_MODE="mount"'' else ""}
              source ${./install.sh}
            ''
          );
        };
    in
    {
      nixosConfigurations = {
        hp-zbook = mkHost { hostname = "hp-zbook"; };
         thinkpad-t470 = mkHost { hostname = "thinkpad-t470"; };
        wifi-chan = mkHost { hostname = "wifi-chan"; };
      };

      apps.x86_64-linux.install = mkInstallApp { hostname = "hp-zbook"; };
      apps.x86_64-linux.resume-install = mkInstallApp { hostname = "hp-zbook"; resume = true; };

      apps.x86_64-linux.install-thinkpad = mkInstallApp { hostname = "thinkpad-t470"; };
      apps.x86_64-linux.resume-install-thinkpad = mkInstallApp { hostname = "thinkpad-t470"; resume = true; };

      apps.x86_64-linux.install-wifi-chan = mkInstallApp { hostname = "wifi-chan"; requireSops = false; };
      apps.x86_64-linux.resume-install-wifi-chan = mkInstallApp { hostname = "wifi-chan"; resume = true; requireSops = false; };
    };
}
