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
        ./boot.nix
        ./hardware.nix

        ../../modules/minimal/base.nix
        ../../modules/minimal/cron.nix
        ../../modules/minimal/locale.nix
        ../../modules/minimal/mdevd.nix
        ../../modules/minimal/network.nix
        ../../modules/minimal/performance.nix
        ../../modules/minimal/user.nix
        ../../modules/minimal/zram.nix

        ../../modules/firewall/default.nix
        ../../modules/installer.nix

        ../../modules/services/fwupd.nix
        ../../modules/services/pihole.nix
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
