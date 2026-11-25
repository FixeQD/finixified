{ config, lib, ... }:
with lib;
{
  imports = [ ../../firewall/default.nix ];

  config = mkIf (config.modules.netbird.enable && config.modules.netbird.openFirewall) {
    modules.firewall.rules.netbird = {
      proto = "udp";
      ports = [ config.modules.netbird.port ];
      comment = "NetBird WireGuard";
    };
    modules.firewall.trustedInterfaces = [ config.modules.netbird.interface ];
  };
}
