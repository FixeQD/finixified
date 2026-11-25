{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.netbird;

  jsonFormat = pkgs.formats.json { };

  netbirdExe = getExe cfg.package;

  configFile = "${cfg.stateDir}/config.json";
  daemonAddr = "unix://${cfg.runtimeDir}/sock";

  baseEnvironment = {
    NB_CONFIG = configFile;
    NB_DAEMON_ADDR = daemonAddr;
    NB_LOG_FILE = concatStringsSep "," cfg.logFiles;
    NB_LOG_LEVEL = cfg.logLevel;
  };

  optionSpecs = [
    {
      value = cfg.mtu;
      env = "NB_MTU";
      settings = "MTU";
      toEnv = toString;
    }
    {
      value = cfg.dnsResolverAddress;
      env = "NB_DNS_RESOLVER_ADDRESS";
      settings = "CustomDNSAddress";
      toEnv = x: x;
    }
    {
      value = cfg.disableDns;
      env = "NB_DISABLE_DNS";
      settings = "DisableDNS";
      toEnv = boolToString;
    }
    {
      value = cfg.disableFirewall;
      env = "NB_DISABLE_FIREWALL";
      settings = "DisableFirewall";
      toEnv = boolToString;
    }
    {
      value = cfg.blockInbound;
      env = "NB_BLOCK_INBOUND";
      settings = "BlockInbound";
      toEnv = boolToString;
    }
    {
      value = cfg.blockLanAccess;
      env = "NB_BLOCK_LAN_ACCESS";
      settings = "BlockLANAccess";
      toEnv = boolToString;
    }
    {
      value = cfg.allowServerSsh;
      env = "NB_ALLOW_SERVER_SSH";
      settings = "ServerSSHAllowed";
      toEnv = boolToString;
    }
    {
      value = cfg.ssh.root;
      env = "NB_ENABLE_SSH_ROOT";
      settings = "EnableSSHRoot";
      toEnv = boolToString;
    }
    {
      value = cfg.ssh.sftp;
      env = "NB_ENABLE_SSH_SFTP";
      settings = "EnableSSHSFTP";
      toEnv = boolToString;
    }
    {
      value = cfg.ssh.localPortForwarding;
      env = "NB_ENABLE_SSH_LOCAL_PORT_FORWARDING";
      settings = "EnableSSHLocalPortForwarding";
      toEnv = boolToString;
    }
    {
      value = cfg.ssh.remotePortForwarding;
      env = "NB_ENABLE_SSH_REMOTE_PORT_FORWARDING";
      settings = "EnableSSHRemotePortForwarding";
      toEnv = boolToString;
    }
    {
      value = cfg.ssh.disableAuth;
      env = "NB_DISABLE_SSH_AUTH";
      settings = "DisableSSHAuth";
      toEnv = boolToString;
    }
    {
      value = cfg.ssh.jwtCacheTtl;
      env = "NB_SSH_JWT_CACHE_TTL";
      settings = "SSHJWTCacheTTL";
      toEnv = toString;
    }
  ];

  activeOptionSpecs = filter (s: s.value != null) optionSpecs;

  mappedClientEnvironment = foldl' (
    acc: s: acc // { ${s.env} = s.toEnv s.value; }
  ) { } activeOptionSpecs;
  mappedSettings = foldl' (acc: s: acc // { ${s.settings} = s.value; }) { } activeOptionSpecs;

  clientEnvironment =
    baseEnvironment
    // mappedClientEnvironment
    // optionalAttrs (cfg.managementUrl != null) { NB_MANAGEMENT_URL = cfg.managementUrl; }
    // optionalAttrs (cfg.hostname != null) { NB_HOSTNAME = cfg.hostname; }
    // optionalAttrs (cfg.extraInterfaceBlacklist != [ ]) {
      NB_EXTRA_IFACE_BLACKLIST = concatStringsSep "," cfg.extraInterfaceBlacklist;
    }
    // optionalAttrs cfg.localMetrics.enable {
      NB_ENABLE_LOCAL_METRICS = "true";
      NB_LOCAL_METRICS_ADDRESS = cfg.localMetrics.address;
    };

  daemonEnvironment =
    cfg.daemonEnvironment
    // baseEnvironment
    // {
      NB_STATE_DIR = cfg.stateDir;
    };

  baseSettings = {
    WgIface = cfg.interface;
    WgPort = cfg.port;
  }
  // mappedSettings
  // optionalAttrs cfg.localMetrics.enable {
    LocalMetricsEnabled = true;
    LocalMetricsAddress = cfg.localMetrics.address;
  };

  settingsFile = jsonFormat.generate "50-finix.json" (
    baseSettings
    // removeAttrs cfg.settings [
      "WgIface"
      "WgPort"
    ]
  );

  exportEnv =
    env:
    concatStringsSep "\n" (
      mapAttrsToList (name: value: "export ${name}=${escapeShellArg (toString value)}") env
    );

  cliWrapper = pkgs.writeShellScriptBin "netbird" ''
    ${exportEnv clientEnvironment}
    exec ${netbirdExe} "$@"
  '';

  uiWrapper = pkgs.writeShellScriptBin "netbird-ui" ''
    exec ${getExe' cfg.uiPackage "netbird-ui"} --daemon-addr=${escapeShellArg daemonAddr} "$@"
  '';

  preStartScript = pkgs.writeShellScript "netbird-prestart" ''
    set -eu

    test -e "$NB_CONFIG" || printf '{}' > "$NB_CONFIG"

    jq -sS 'reduce .[] as $i ({}; . * $i)' \
      "$NB_CONFIG" \
      /etc/netbird/config.d/*.json \
      > "$NB_CONFIG.new"

    if ! diff <(jq -S < "$NB_CONFIG") "$NB_CONFIG.new"; then
      mv "$NB_CONFIG.new" "$NB_CONFIG"
    else
      rm "$NB_CONFIG.new"
    fi
  '';

  loginScript = pkgs.writeShellScript "netbird-login" ''
    set -eu

    status() {
      ${netbirdExe} status 2>&1 || :
    }

    i=0
    until ${netbirdExe} status --check live > /dev/null 2>&1; do
      i=$((i + 1))
      if [ "$i" -ge "${toString cfg.loginTimeout}" ]; then
        echo "netbird: daemon did not become ready" >&2
        exit 1
      fi
      sleep 1
    done

    ${optionalString (cfg.preSharedKeyFile != null) ''
      NB_PRESHARED_KEY="$(${pkgs.coreutils}/bin/cat ${escapeShellArg (toString cfg.preSharedKeyFile)})"
      export NB_PRESHARED_KEY
    ''}

    # A registered peer reconnects from its profile without the setup key.
    if status | grep -q 'NeedsLogin'; then
      ${netbirdExe} up ${escapeShellArgs cfg.extraUpFlags}
    fi
  '';
in
{
  config = mkIf cfg.enable {
    # NetBird validates SSH JWTs against `iat`
    # Clock skew makes it reject them as "token used before issued" so the daemon needs a synced clock.
    services.chrony.enable = true;

    assertions = [
      {
        assertion = cfg.setupKeyFile != null;
        message = "modules.netbird.setupKeyFile must point to a setup key file";
      }
    ];

    environment = {
      systemPackages = [ cliWrapper ] ++ optionals cfg.desktop [ uiWrapper ];
      pathsToLink = optionals cfg.desktop [ "/share/applications" ];
      etc."netbird/config.d/50-finix.json".source = settingsFile;
    };

    finit = {
      tmpfiles.rules = [
        "d ${cfg.stateDir} 0700 root root -"
        "d ${cfg.runtimeDir} 0755 root root -"
      ];

      services.netbird = {
        description = "NetBird mesh VPN daemon";
        runlevel = "2345";
        conditions = [
          "service/syslogd/ready"
          "service/dhcpcd/ready"
        ];
        command = "${netbirdExe} service run ${escapeShellArgs cfg.extraServiceFlags}";
        environment = daemonEnvironment;
        path = [
          cfg.package
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.jq
          pkgs.diffutils
          pkgs.nftables
          # NetBird's SSH server execs `login`/`su` to switch to the target user.
          pkgs.shadow
          pkgs.util-linux
        ];
        exec-start-pre = "${preStartScript}";
        notify = "pid";
        reload-signal = "none";
        reload-triggers = [ settingsFile ];
        respawn = true;
        log = true;
      };

      tasks.netbird-login = {
        description = "Register the host with NetBird using the sops setup key";
        runlevel = "2345";
        conditions = [ "service/netbird/ready" ];
        command = "${loginScript}";
        environment = clientEnvironment // {
          NB_SETUP_KEY_FILE = toString cfg.setupKeyFile;
        };
        path = [
          cfg.package
          pkgs.coreutils
          pkgs.gnugrep
        ];
        remain-after-exit = true;
        log = true;
      };
    };
  };
}
