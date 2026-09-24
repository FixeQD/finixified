{ lib, ... }:
with lib;
{
  options.modules.installer = {
    requireSops = mkOption {
      type = types.bool;
      default = false;
      description = "Whether the host installer requires SOPS setup.";
    };
  };
}
