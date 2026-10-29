{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.cockpit;

  settingsFormat = pkgs.formats.ini { };
  configFile = settingsFormat.generate "cockpit.conf" cfg.settings;

  # Sessions inherit ws's cwd, and the user's shell (fish) complains when it can't open it.
  # /run/cockpit/xdg is read after /etc, so other modules can drop a cockpit.conf there to override settings at runtime.
  wsStart = pkgs.writeShellScript "cockpit-ws-start" ''
    cd /
    export XDG_CONFIG_DIRS=/run/cockpit/xdg
    exec ${cfg.package}/libexec/cockpit-ws --no-tls --address ${cfg.bindAddr} --port ${toString cfg.port}
  '';

  pathPkgs = [ cfg.package ] ++ cfg.plugins;

  resourcesEnv = pkgs.buildEnv {
    name = "cockpit-plugins";
    paths = pathPkgs;
    pathsToLink = [ "/share/cockpit" ];
  };

  depsEnv = pkgs.buildEnv {
    name = "cockpit-plugins-env";
    paths = concatMap (p: p.passthru.cockpitPath or [ ]) pathPkgs;
    pathsToLink = [ "/bin" "/share" "/lib" ];
  };

  share = pkgs.buildEnv {
    name = "cockpit-share";
    paths = [ resourcesEnv depsEnv ];
    pathsToLink = [ "/share" ];
  };
in
{
  imports = [ ../firewall/cockpit.nix ];

  options.modules.cockpit = {
    enable = mkEnableOption "Cockpit web console";

    package = mkPackageOption pkgs "cockpit" { };

    plugins = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression "[ pkgs.cockpit-machines pkgs.cockpit-files ]";
      description = ''
        Cockpit plugins. Each one contributes its `share/cockpit` and its
        `passthru.cockpitPath` (runtime dependencies).
      '';
    };

    bindAddr = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address cockpit-ws listens on.";
    };

    port = mkOption {
      type = types.port;
      default = 9090;
      description = "Port cockpit-ws listens on.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the Cockpit port in `modules.firewall`.";
    };

    allowedOrigins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "https://cockpit.example.com" ];
      description = ''
        Extra origins allowed in `WebService.Origins`. Localhost is always included. 
        When serving through an HTTPS reverse proxy, add its origin here and set `settings.WebService.ProtocolHeader`.
      '';
    };

    disallowedUsers = mkOption {
      type = types.listOf types.str;
      default = [ "root" ];
      description = "Users that are not allowed to log in to Cockpit.";
    };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      example = literalExpression ''
        {
          WebService.AllowUnencrypted = true;
        }
      '';
      description = "Contents of /etc/cockpit/cockpit.conf, see `man cockpit.conf.5`.";
    };
  };

  config = mkIf cfg.enable {
    modules.cockpit.allowedOrigins = [
      "http://localhost:${toString cfg.port}"
      "http://127.0.0.1:${toString cfg.port}"
    ];

    modules.cockpit.settings = {
      WebService = {
        Origins = concatStringsSep " " cfg.allowedOrigins;
        LoginTo = mkDefault false;
      };

      # No systemd socket activation for /run/cockpit/session, so ws spawns cockpit-session directly.
      basic.Command = mkDefault "${cfg.package}/libexec/cockpit-session";

      # Browsers try Kerberos first, which fails noisily without the socket.
      negotiate.action = mkDefault "none";
    };

    environment.etc = {
      "cockpit/cockpit.conf".source = configFile;
      "cockpit/share".source = "${share}/share";
      "cockpit/bin".source = "${depsEnv}/bin";
      "cockpit/lib".source = "${depsEnv}/lib";
    };

    security.pam.services.cockpit.text = mkDefault ''
      ${optionalString (cfg.disallowedUsers != [ ]) "account required pam_succeed_if.so user notin ${concatStringsSep ":" cfg.disallowedUsers}"}
      ${config.security.pam.services.login.text}
    '';

    finit.services.cockpit = {
      description = "Cockpit web console";
      runlevel = "2345";
      conditions = [ "service/syslogd/ready" ];
      command = "${wsStart}";
      respawn = true;
      log = true;

      # ws only reads cockpit.conf on start
      reload-signal = "none";
      reload-triggers = [ "${configFile}" ];
    };
  };
}
