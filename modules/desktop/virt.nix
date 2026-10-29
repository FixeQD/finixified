{ pkgs, lib, config, finix, ... }:
with lib;
let cfg = config.modules.virt; in
{
  imports = [ finix.nixosModules.docker ];

  options.modules.virt.enable = mkEnableOption "Docker and libvirt";

  config = mkIf cfg.enable {
    services.docker = {
      enable = true;
      prune.enable = false;
    };

    finit.services.libvirtd = {
      description = "libvirt virtualisation daemon";
      runlevels   = "2345";
      conditions  = [ "service/syslogd/ready" ];
      command     = "${pkgs.libvirt}/bin/libvirtd";
    };

    environment.systemPackages = with pkgs; [
      virt-manager
      qemu
      virt-viewer
      spice-gtk
      virtiofsd
    ];
  };
}
