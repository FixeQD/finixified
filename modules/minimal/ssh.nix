{
  config,
  pkgs,
  lib,
  finix,
  ...
}:
with lib;
{
  imports = [
    ./user.nix
    finix.nixosModules.openssh
  ];

  options.modules.ssh = {
    openssh = {
      enable = mkEnableOption "OpenSSH server";
      permitRootLogin = mkOption {
        type = types.enum [
          "yes"
          "without-password"
          "prohibit-password"
          "forced-commands-only"
          "no"
        ];
        default = "prohibit-password";
        description = "Whether the root user can login using ssh.";
      };
      passwordAuthentication = mkOption {
        type = types.bool;
        default = false;
        description = "Whether password authentication is allowed.";
      };
    };
  };

  config = mkIf config.modules.user.enable {
    environment.variables = {
      SSH_ASKPASS = lib.getExe (pkgs.callPackage ../helpers/askpass.nix { });
    };

    environment.systemPackages = [
      pkgs.keychain
      pkgs.openssh
    ];

    environment.etc."ssh/ssh_config".text = ''
      Include /etc/ssh/ssh_config.d/*.conf

      Host *
        AddKeysToAgent yes
        ServerAliveInterval 60
        ServerAliveCountMax 3
    '';

    services.openssh = mkIf config.modules.ssh.openssh.enable {
      enable = true;
      settings = {
        PermitRootLogin = config.modules.ssh.openssh.permitRootLogin;
        PasswordAuthentication = config.modules.ssh.openssh.passwordAuthentication;
      };
    };
  };
}
