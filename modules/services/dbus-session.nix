{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.dbus-session;
  dbus = cfg.package;
  busStart = pkgs.writeShellScript "dbus-session-start" ''
    set -eu

    : "''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set, is a sessiond session opened?}"
    bus="$XDG_RUNTIME_DIR/bus"

    if ${dbus}/bin/dbus-send --address="unix:path=$bus" --dest=org.freedesktop.DBus \
        --type=method_call --print-reply / org.freedesktop.DBus.ListNames >/dev/null 2>&1
    then
      exec ${pkgs.coreutils}/bin/sleep infinity
    fi

    rm -f "$bus"
    exec ${dbus}/bin/dbus-daemon --session --nofork --address="unix:path=$bus"
  '';

  sessionEnv = pkgs.writeText "dbus-session.sh" ''
    if [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
      DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
      export DBUS_SESSION_BUS_ADDRESS
    fi
  '';

in
{
  options.services.dbus-session = {
    enable = mkEnableOption ''
      a per-user D-Bus session bus, started and stopped with the user's
      sessiond session
    '';

    package = mkPackageOption pkgs "dbus" { };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = [ dbus ];
      environment.etc."profile.d/dbus-session.sh".source = sessionEnv;

      services.sessiond-hooks.hooks.dbus-session.settings = {
        on_start = toString busStart;
        restart.on = "Failure";
        restart.delay = 5;
      };
    })

    {
      assertions = [
        {
          assertion = config.services.dbus-session.enable -> config.services.sessiond.enable;
          message = ''
            services.dbus-session.enable requires services.sessiond.enable: the
            session bus is spawned per user by sessiond-hooks.
          '';
        }
        {
          assertion = config.services.dbus-session.enable -> config.services.sessiond-hooks.enable;
          message = ''
            services.dbus-session.enable requires services.sessiond-hooks.enable,
            it is what actually starts the bus for every logged in user.
          '';
        }
      ];
    }
  ];
}
