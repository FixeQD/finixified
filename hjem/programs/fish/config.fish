fish_add_path --global --path --append /run/wrappers/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin
set -e fish_history
set -gx GPG_TTY (tty)

if set -q XDG_RUNTIME_DIR
    set -gx DBUS_SESSION_BUS_ADDRESS "unix:path=$XDG_RUNTIME_DIR/bus"
else
    set -e DBUS_SESSION_BUS_ADDRESS
end
