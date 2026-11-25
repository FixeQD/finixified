{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  jsonFormat = pkgs.formats.json { };
in
{
  options.modules.netbird = {
    enable = mkEnableOption "NetBird mesh VPN";

    package = mkPackageOption pkgs "netbird" { };

    uiPackage = mkPackageOption pkgs "netbird-ui" { };

    desktop = mkEnableOption "NetBird GUI (netbird-ui)";

    setupKeyFile = mkOption {
      type = with types; nullOr path;
      default = attrByPath [ "sops" "secrets" "netbird_key" "path" ] null config;
      description = "Path to a setup key file; defaults to the `netbird_key` sops secret.";
    };

    preSharedKeyFile = mkOption {
      type = with types; nullOr path;
      default = null;
      description = "Path to a WireGuard PSK file, read into NB_PRESHARED_KEY at registration.";
    };

    interface = mkOption {
      type = types.str;
      default = "wt0";
      description = "Name of the WireGuard interface managed by NetBird.";
    };

    port = mkOption {
      type = types.port;
      default = 51820;
      description = "UDP port NetBird listens on for peer connections.";
    };

    stateDir = mkOption {
      type = types.path;
      default = "/var/lib/netbird";
      description = "Persistent state directory (config.json, state.json, resolv.conf).";
    };

    runtimeDir = mkOption {
      type = types.path;
      default = "/run/netbird";
      description = "Runtime directory holding the daemon control socket.";
    };

    logLevel = mkOption {
      type = types.enum [
        "panic"
        "fatal"
        "error"
        "warn"
        "warning"
        "info"
        "debug"
        "trace"
      ];
      default = "info";
      description = "NetBird log level.";
    };

    logFiles = mkOption {
      type = types.listOf types.str;
      default = [ "console" ];
      example = [
        "console"
        "syslog"
      ];
      description = "Log destinations passed as NB_LOG_FILE.";
    };

    managementUrl = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "https://netbird.example.com:443";
      description = "Self-hosted Management Service URL. Null uses NetBird Cloud.";
    };

    hostname = mkOption {
      type = with types; nullOr str;
      default = null;
      description = "Custom hostname registered with the management service.";
    };

    mtu = mkOption {
      type = with types; nullOr (ints.between 576 8192);
      default = null;
      description = "WireGuard MTU. Null lets NetBird/management decide (normally 1280).";
    };

    dnsResolverAddress = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "127.0.0.1:5053";
      description = "Explicit address for NetBird's local DNS resolver.";
    };

    extraInterfaceBlacklist = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "wlan0" ];
      description = "Additional interfaces NetBird should ignore when listening.";
    };

    disableDns = mkOption {
      type = with types; nullOr bool;
      default = null;
      description = "Pass --disable-dns to `netbird up`. Null leaves the setting untouched.";
    };

    disableFirewall = mkOption {
      type = with types; nullOr bool;
      default = null;
      description = "Pass --disable-firewall to `netbird up`. Beware: this also disables routing/NAT.";
    };

    blockInbound = mkOption {
      type = with types; nullOr bool;
      default = null;
      description = "Pass --block-inbound to `netbird up`.";
    };

    blockLanAccess = mkOption {
      type = with types; nullOr bool;
      default = null;
      description = "Pass --block-lan-access to `netbird up`.";
    };

    allowServerSsh = mkOption {
      type = with types; nullOr bool;
      default = null;
      description = "Pass --allow-server-ssh to `netbird up`, enabling the peer's SSH server.";
    };

    ssh = {
      root = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Pass --enable-ssh-root to `netbird up`.";
      };

      sftp = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Pass --enable-ssh-sftp to `netbird up`.";
      };

      localPortForwarding = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Pass --enable-ssh-local-port-forwarding to `netbird up`.";
      };

      remotePortForwarding = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Pass --enable-ssh-remote-port-forwarding to `netbird up`.";
      };

      disableAuth = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Pass --disable-ssh-auth to `netbird up`. Allows any permitted peer without SSO.";
      };

      jwtCacheTtl = mkOption {
        type = with types; nullOr (ints.between 0 600);
        default = null;
        description = "Pass --ssh-jwt-cache-ttl to `netbird up`.";
      };
    };

    localMetrics = {
      enable = mkEnableOption "NetBird local Prometheus /metrics endpoint";

      address = mkOption {
        type = types.str;
        default = "127.0.0.1:9191";
        description = "Listen address of the local metrics endpoint.";
      };
    };

    loginTimeout = mkOption {
      type = types.ints.positive;
      default = 30;
      description = "Seconds to wait for `netbird status --check live` before giving up.";
    };

    extraUpFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--enable-ssh-sftp"
        "--extra-dns-labels=lab"
      ];
      description = "Additional flags for `netbird up`. They are not mirrored into config.d; use the typed options for that.";
    };

    extraServiceFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--disable-update-settings" ];
      description = "Additional flags for `netbird service run`.";
    };

    daemonEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          NB_NFTABLES_TABLE = "nb";
          NB_WG_KERNEL_DISABLED = "true";
        }
      '';
      description = "Extra daemon environment variables (advanced NB_* settings). Generated paths and logging take precedence.";
    };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = literalExpression ''
        {
          ManagementURL = { Scheme = "https"; Host = "netbird.example.com:443"; };
          IFaceBlackList = [ "br-metamcp" ];
        }
      '';
      description = "Profile settings merged from /etc/netbird/config.d/50-finix.json at daemon start.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open the NetBird UDP port and trust its interface.";
    };
  };
}
