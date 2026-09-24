{
  disko,
  community-modules,
  finix,
  ...
}:
{
  specialArgs = {
    inherit disko community-modules finix;
  };

  modules = [
    {
      imports = [
        ./hardware.nix
        ./boot.nix

        ../../modules/minimal/base.nix
        ../../modules/minimal/locale.nix
        ../../modules/minimal/network.nix
        ../../modules/minimal/cron.nix
        ../../modules/minimal/performance.nix
        ../../modules/minimal/zram.nix
        ../../modules/minimal/user.nix
        ../../modules/minimal/mdevd.nix
        ../../modules/installer.nix
        ../../modules/services/fwupd.nix
        ../../modules/services/pihole.nix
        ../../modules/firewall/default.nix
      ];

      networking.hostName = "wifi-chan";

      modules = {
        base.enable = true;
        locale.enable = true;
        mdevd.enable = true;

        network.enable = true;
        network.openssh.enable = true;
        network.openssh.permitRootLogin = "no";
        network.tailscale.enable = true;

        cron.enable = true;
        performance.enable = true;
        firewall.enable = true;
        firewall.trustedInterfaces = [ "tailscale0" ];
        fwupd.enable = true;
        installer.requireSops = false;
        zram.enable = true;

        user.enable = true;
        user.name = "fixeq";

        pihole = {
          enable = true;
          port = 2137;
          settings = {
            dns.upstreams = [
              "9.9.9.9"
              "149.112.112.112"
            ];
          };
        };
      };

      finit.runlevel = 3;
    }
  ];
}
