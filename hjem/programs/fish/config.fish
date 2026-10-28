fish_add_path --global --path --append /run/wrappers/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin
set -e fish_history
set -gx GPG_TTY (tty)
