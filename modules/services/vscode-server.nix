{ pkgs, lib, config, inputs, ... }:
with lib;
let
  cfg = config.modules.vscode-server;
  autoFixVscodeServer = pkgs.callPackage "${inputs.vscode-server}/pkgs/auto-fix-vscode-server.nix" {
    enableFHS = cfg.enableFHS;
    nodejsPackage = cfg.nodejsPackage;
    extraRuntimeDependencies = cfg.extraRuntimeDependencies;
    installPath = cfg.installPath;
    postPatch = cfg.postPatch;
  };
in
{
  options.modules.vscode-server = {
    enable = mkEnableOption "VS Code Server support";

    user = mkOption {
      type = types.str;
      default = config.modules.user.name;
      description = "User whose VS Code Server installation should be monitored.";
    };

    enableFHS = mkEnableOption "an FHS-compatible VS Code Server environment";

    nodejsPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Node.js package used by the VS Code Server.";
    };

    extraRuntimeDependencies = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional runtime dependencies for VS Code Server binaries.";
    };

    installPath = mkOption {
      type = types.coercedTo types.str (path: [ path ]) (types.listOf types.str);
      default = [ "$HOME/.vscode-server" ];
      description = "Paths containing VS Code Server installations to monitor.";
    };

    postPatch = mkOption {
      type = types.lines;
      default = "";
      description = "Shell commands run after a VS Code Server installation is patched.";
    };
  };

  config = mkIf cfg.enable {
    finit.services.vscode-server = {
      description = "VS Code Server auto-fix monitor";
      runlevel = "2345";
      conditions = [ "service/syslogd/ready" ];
      user = cfg.user;
      group = config.users.users.${cfg.user}.group;
      command = getExe autoFixVscodeServer;
      respawn = true;
      log = true;
    };
  };
}
