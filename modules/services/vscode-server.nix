{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.vscode-server;

  codeServerStart = pkgs.writeShellScript "code-server-start" ''
    set -euo pipefail
    ${optionalString (cfg.hashedPasswordFile != null) ''
      HASHED_PASSWORD="$(${pkgs.coreutils}/bin/cat ${escapeShellArg (toString cfg.hashedPasswordFile)})"
      export HASHED_PASSWORD
    ''}
    exec ${cfg.package}/bin/code-server \
      --bind-addr ${cfg.bindAddr}:${toString cfg.port} \
      --auth ${if cfg.hashedPasswordFile == null then "none" else "password"} \
      --disable-telemetry \
      ${escapeShellArgs cfg.extraFlags}
  '';
in
{
  options.modules.vscode-server = {
    enable = mkEnableOption "code-server (VS Code in the browser)";

    package = mkOption {
      type = types.package;
      default = pkgs.code-server;
      description = "Package for code-server.";
    };

    user = mkOption {
      type = types.str;
      default = config.modules.user.name;
      description = "User under which code-server will run.";
    };

    bindAddr = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address to which code-server will bind.";
    };

    port = mkOption {
      type = types.port;
      default = 8443;
      description = "Port to which code-server will bind.";
    };

    hashedPasswordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/code_server_hashed_password";
      description = ''
        Path to a file containing the hashed password for code-server.
        If not set, code-server will run without authentication.
      '';
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--disable-update-check" ];
      description = "Additional flags for code-server.";
    };
  };

  config = mkIf cfg.enable {
    finit.services.code-server = {
      description = "code-server (VS Code in the browser)";
      runlevel = "2345";
      conditions = [ "service/syslogd/ready" ];

      user = cfg.user;
      group = config.users.users.${cfg.user}.group;

      command = "${codeServerStart}";
      respawn = true;
      log = true;
    };
  };
}
