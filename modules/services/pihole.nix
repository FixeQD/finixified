{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.pihole;

  configDir = "/etc/pihole";
  stateDir = "/var/lib/pihole";
  logDir = "/var/log/pihole";

  settingsFormat = pkgs.formats.toml { };

  baseSettings = {
    misc = {
      readOnly = true;
      privacylevel = cfg.privacyLevel;
    };
    webserver = {
      domain = cfg.host;
      port = toString cfg.port;
      paths = {
        webroot = "${cfg.webPackage}/share/";
        webhome = "/";
      };
    };
    files = {
      database = "${stateDir}/pihole-FTL.db";
      gravity = "${stateDir}/gravity.db";
      macvendor = "${stateDir}/macvendor.db";
      log = {
        ftl = "${logDir}/FTL.log";
        dnsmasq = "${logDir}/pihole.log";
        webserver = "${logDir}/webserver.log";
      };
    };
  };

  settings = recursiveUpdate baseSettings cfg.settings;
  configFile = settingsFormat.generate "pihole.toml" settings;
in
{
  imports = [ ../firewall/pihole.nix ];

  options.modules.pihole = {
    enable = mkEnableOption "Pi-hole (FTL + web UI) network-wide DNS ad/tracker blocker";

    package = mkOption {
      type = types.package;
      default = pkgs.pihole-ftl;
      description = "The pihole-ftl package to use.";
    };

    piholePackage = mkOption {
      type = types.package;
      default = pkgs.pihole;
      description = "The pihole admin CLI package to use.";
    };

    webPackage = mkOption {
      type = types.package;
      default = pkgs.pihole-web;
      description = "The pihole-web (static dashboard assets) package to use.";
    };

    host = mkOption {
      type = types.str;
      default = "pi.hole";
      description = "Domain name the web UI answers to.";
    };

    port = mkOption {
      type = types.port;
      default = 80;
      description = "Port the Pi-hole webserver listens on.";
    };

    privacyLevel = mkOption {
      type = types.ints.between 0 3;
      default = 0;
      description = "Level of detail in generated statistics. 0 = full, 3 = anonymous only.";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      example = literalExpression ''
        {
          dns.upstreams = [ "9.9.9.9" "149.112.112.112" ];
        }
      '';
      description = ''
        Declarative Pi-hole config, merged into /etc/pihole/pihole.toml
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.piholePackage ];

    environment.etc."pihole/pihole.toml".source = configFile;

    finit.tmpfiles.rules = [
      "d ${configDir} 0755 root root -"
      "d ${stateDir} 0700 root root -"
      "d ${logDir} 0700 root root -"
    ];

    finit.services.pihole-ftl = {
      description = "Pi-hole FTL";
      conditions = [
        "service/syslogd/ready"
        "service/dhcpcd/ready"
      ];
      command = "${cfg.package}/bin/pihole-FTL no-daemon";
      path = [ pkgs.coreutils ];
      respawn = true;
      log = true;
    };
  };
}
