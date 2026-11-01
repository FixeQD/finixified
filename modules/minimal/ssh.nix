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
      SSH_AUTH_SOCK = "/run/user/$(id -u)/ssh-agent/ssh-agent.sock";
    };

    finit.services.ssh-agent = {
      description = "SSH agent for ${config.modules.user.name}";
      user = config.modules.user.name;
      group = config.users.users.${config.modules.user.name}.group;
      extra-groups = config.users.users.${config.modules.user.name}.extraGroups;
      command = pkgs.writeShellScript "ssh-agent-service" ''
        agent_dir="/run/user/$(id -u)/ssh-agent"
        mkdir -p "$agent_dir"
        sock="$agent_dir/ssh-agent.sock"
        pid_file="$agent_dir/ssh-agent.pid"
        rm -f "$sock" "$pid_file"
        trap 'kill "$(cat "$pid_file" 2>/dev/null)" 2>/dev/null; exit 0' TERM INT
        ${pkgs.openssh}/bin/ssh-agent -D -a "$sock" &
        agent_pid=$!
        echo "$agent_pid" > "$pid_file"
        wait "$agent_pid"
      '';
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
