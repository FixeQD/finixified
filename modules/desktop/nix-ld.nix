{ lib, config, community-modules, ... }:
with lib;
let cfg = config.modules.nix-ld; in
{
  imports = [ community-modules.nixosModules.nix-ld ];

  options.modules.nix-ld = {
    enable = mkEnableOption "nix-ld (community-modules programs.nix-ld)";

    libraries = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra libraries exposed via NIX_LD_LIBRARY_PATH to unpatched binaries.";
    };
  };

  config = mkIf cfg.enable {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = cfg.libraries;
  };
}
