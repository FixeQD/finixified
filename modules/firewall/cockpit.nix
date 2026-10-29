{ config, lib, ... }:
with lib;
{
  imports = [ ./default.nix ];

  config = mkIf (config.modules.cockpit.enable && config.modules.cockpit.openFirewall) {
    modules.firewall.rules.cockpit = {
      proto = "tcp";
      ports = [ config.modules.cockpit.port ];
      comment = "Cockpit web console";
    };
  };
}
