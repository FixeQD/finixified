{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.cockpit;

  settingsFormat = pkgs.formats.ini { };
  configFile = settingsFormat.generate "cockpit.conf" cfg.settings;

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
        Addons for Cockpit. Each addon contributes its `share/cockpit` and `passthru.cockpitPath`
      '';
    };

    bindAddr = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address which cockpit-ws listens on.";
    };

    port = mkOption {
      type = types.port;
      default = 9090;
      description = "Port, on which cockpit-ws listens.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Opens the Cockpit port in modules.firewall.";
    };

    allowedOrigins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "https://cockpit.example.com" ];
      description = ''
        Additional origins allowed in `WebService.Origins`. Localhost is added automatically. 
        If you are accessing through a reverse proxy or tunnel with HTTPS, enter 
        its address here and set `settings.WebService.ProtocolHeader = "X-Forwarded-Proto"`.
      '';
    };

    disallowedUsers = mkOption {
      type = types.listOf types.str;
      default = [ "root" ];
      example = [ "john" "jane" ];
      description = "Users who are not allowed to log in to Cockpit.";
    };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      example = literalExpression ''
        {
          WebService.AllowUnencrypted = true;
        }
      '';
      description = ''
        Content of /etc/cockpit/cockpit.conf, see `man cockpit.conf.5`.
      '';
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
      basic.Command = mkDefault "${cfg.package}/libexec/cockpit-session";
    };

    environment.etc = {
      "cockpit/cockpit.conf".source = configFile;
      "cockpit/disallowed-users".text = concatMapStrings (u: "${u}\n") cfg.disallowedUsers;
      "cockpit/share".source = "${share}/share";
      "cockpit/bin".source = "${depsEnv}/bin";
      "cockpit/lib".source = "${depsEnv}/lib";
    };

    security.pam.services.cockpit.text = mkDefault ''
      account required pam_listfile.so item=user sense=deny file=/etc/cockpit/disallowed-users onerr=succeed
      ${config.security.pam.services.login.text}
    '';

    finit.services.cockpit = {
      description = "Cockpit web console";
      runlevel = "2345";
      conditions = [ "service/syslogd/ready" ];
      command = "${cfg.package}/libexec/cockpit-ws --no-tls --address ${cfg.bindAddr} --port ${toString cfg.port}";
      respawn = true;
      log = true;

      reload-signal = "none";
      reload-triggers = [ "${configFile}" ];
    };
  };
}
