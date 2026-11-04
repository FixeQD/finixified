{
  config,
  pkgs,
  lib,
  finix,
  ...
}:
with lib;
let
  askpass = lib.getExe (pkgs.callPackage ../helpers/askpass.nix { });
in
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
      SSH_AUTH_SOCK = "/run/user/$(id -u)/ssh-agent/ssh-agent.sock";
      SSH_ASKPASS = askpass;
    };

    finit.services.ssh-agent = {
      description = "SSH agent for ${config.modules.user.name}";
      user = config.modules.user.name;
      group = config.users.users.${config.modules.user.name}.group;
      extra-groups = config.users.users.${config.modules.user.name}.extraGroups;
      command = pkgs.writeShellScript "ssh-agent-service" ''
        export XDG_RUNTIME_DIR="/run/user/$(${pkgs.coreutils}/bin/id -u)"

        agent_dir="/run/user/$(${pkgs.coreutils}/bin/id -u)/ssh-agent"
        sock="$agent_dir/ssh-agent.sock"
        pid_file="$agent_dir/ssh-agent.pid"
        ${pkgs.coreutils}/bin/rm -f "$sock" "$pid_file"
        ${pkgs.coreutils}/bin/mkdir -p "$agent_dir"
        trap 'kill "$(${pkgs.coreutils}/bin/cat "$pid_file" 2>/dev/null)" 2>/dev/null; exit 0' TERM INT
        ${pkgs.openssh}/bin/ssh-agent -D -a "$sock" &
        agent_pid=$!
        ${pkgs.coreutils}/bin/echo "$agent_pid" > "$pid_file"
        wait "$agent_pid"
      '';
      environment = {
        SSH_ASKPASS = askpass;
        SSH_ASKPASS_REQUIRE = "force";
      };

      log = { };

      respawn = true;
    };

    services.openssh = mkIf config.modules.ssh.openssh.enable {
      enable = true;
      settings = {
        PermitRootLogin = config.modules.ssh.openssh.permitRootLogin;
        PasswordAuthentication = config.modules.ssh.openssh.passwordAuthentication;
      };
    };
  };
}
