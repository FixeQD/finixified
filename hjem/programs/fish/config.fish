fish_add_path --global --path --append /run/wrappers/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin
set -e fish_history
set -gx GPG_TTY (tty)

if set -q XDG_RUNTIME_DIR
    set -gx DBUS_SESSION_BUS_ADDRESS "unix:path=$XDG_RUNTIME_DIR/bus"
else
    set -e DBUS_SESSION_BUS_ADDRESS
end

set -l ssh_keys (
    path filter --type=file ~/.ssh/id_ed25519_sk_rk_* |
    string match -rv '\.pub$'
)

set -gx SSH_ASKPASS @lib.getExe (pkgs.callPackage (inputs.self.outPath + "/modules/helpers/askpass.nix") { })@
set -gx SSH_ASKPASS_REQUIRE force

if test (count $ssh_keys) -gt 0
    @pkgs.keychain@/bin/keychain --quiet --immediate add $ssh_keys --eval --no-inherit | source
else
    @pkgs.keychain@/bin/keychain --quiet --immediate agent start --eval | source
end
