{
  pkgs,
  lib,
  config,
  finix,
  ...
}:
with lib;
let
  cfg = config.modules.user;
  #runtimeDirCmd = "/run/user/$(${pkgs.coreutils}/bin/id -u ${cfg.name})";

  capabilityList = concatStringsSep "," cfg.capabilities;
  pamCap = "${pkgs.libcap.pam}/lib/security/pam_cap.so";
  pamCapLine = "auth optional ${pamCap} defer keepcaps # ambient capabilities (order 5000)";

  capServices = {
    login = true;
    su = true;
    ly = config.services.ly.enable or false;
    cosmic-greeter = config.programs.cosmic-greeter.enable or false;
    greetd = config.services.greetd.enable or false;
    lemurs = config.services.lemurs.enable or false;
    sddm = config.services.displayManager.sddm.enable or config.services.sddm.enable or false;
    sddm-autologin =
      config.services.displayManager.sddm.autoLogin.enable or config.services.sddm.autoLogin.enable
        or false;
    autologin = config.services.autologin.enable or false;
  };
in
{
  imports = [
    finix.nixosModules.sudo
  ];

  options.modules.user = {
    enable = mkEnableOption "primary user and sudo";
    name = mkOption {
      type = types.str;
      description = "Primary user login name";
    };
    capabilities = mkOption {
      type = types.listOf types.str;
      default = [
        "cap_perfmon"
        "cap_bpf"
        "cap_sys_ptrace"
        "cap_syslog"
        "cap_ipc_lock"
        "cap_sys_resource"
      ];
      example = [
        "cap_perfmon"
        "cap_bpf"
      ];
      description = ''
        Linux capabilities granted to the primary user via pam_cap (/etc/security/capability.conf) for interactive sessions.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.name;
      shell = pkgs.fish;
      passwordFile = "/persist/user-passwords/${cfg.name}";
      extraGroups = [
        "wheel"
        "seat"
        "storage"
        "power"
        "audio"
        "video"
        "optical"
        "network"
        "input"
        "docker"
        "libvirtd"
        "kvm"
        "adbusers"
        "fido"
      ];
    };

    users.users.root.passwordFile = "/persist/user-passwords/root";

    programs.sudo.enable = true;

    environment.etc."security/capability.conf".text = mkIf (cfg.capabilities != [ ]) ''
      ^${capabilityList} ${cfg.name}
    '';

    security.pam.services = mkMerge (
      mapAttrsToList (
        svc: enabled:
        mkIf (enabled && cfg.capabilities != [ ]) {
          ${svc}.text = mkOrder 500 pamCapLine;
        }
      ) capServices
    );

    #finit.tasks.user-runtime-dir = {
    #  description = "Create ${cfg.name}'s XDG_RUNTIME_DIR";
    #  runlevels = "2345";
    #  conditions = [ "service/seatd/ready" ];
    #  command = pkgs.writeShellScript "user-runtime-dir" ''
    #    dir="${runtimeDirCmd}"
    #    mkdir -p "$dir"
    #    chown ${cfg.name}:${config.users.users.${cfg.name}.group} "$dir"
    #    chmod 0700 "$dir"
    #  '';
    #};
  };
}
