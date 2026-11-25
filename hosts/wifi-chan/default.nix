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
        ../../modules/minimal/udev.nix
        ../../modules/minimal/network.nix
        ../../modules/minimal/performance.nix
        ../../modules/minimal/ssh.nix
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
        udev.enable = true;

        network.enable = true;
        ssh.openssh.enable = true;
        ssh.openssh.permitRootLogin = "no";

        cron.enable = true;
        performance.enable = true;
        firewall.enable = true;
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
