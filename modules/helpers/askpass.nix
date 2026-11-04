{
  lib,
  writeShellApplication,
  coreutils,
  kdePackages,
}:
writeShellApplication {
  name = "ssh-askpass";
  runtimeInputs = [ coreutils ];
  text = ''
    prompt="''${1:-Password: }"
    runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    if [ ! -S "$runtime/''${WAYLAND_DISPLAY:-}" ]; then
      unset WAYLAND_DISPLAY
      for sock in "$runtime"/wayland-*; do
        name="''${sock##*/}"
        if [[ "$name" =~ ^wayland-[0-9]+$ ]] && [ -S "$sock" ]; then
          export WAYLAND_DISPLAY="$name"
          break
        fi
      done
    fi

    if [ -n "''${WAYLAND_DISPLAY:-}" ] || [ -n "''${DISPLAY:-}" ]; then
      exec ${lib.getExe kdePackages.ksshaskpass} "$@"
    fi

    if ! (: </dev/tty) 2>/dev/null; then
      exit 1
    fi
    exec 3<>/dev/tty

    password=""
    redraw() {
      printf '\r\033[K%s%s' "$prompt" "''${password//?/*}" >&3
    }

    old_stty="$(stty -F /dev/tty -g)"
    trap 'stty -F /dev/tty "$old_stty"' EXIT
    stty -F /dev/tty -echo
    redraw

    while IFS= read -r -s -n1 char <&3; do
      if [ -z "$char" ]; then
        break
      fi
      case "$char" in
        $'\177'|$'\b')
          if [ -n "$password" ]; then
            password="''${password%?}"
            redraw
          fi
          ;;
        $'\e')
          IFS= read -r -s -n2 -t 0.01 _ <&3 || true
          ;;
        *)
          password+="$char"
          redraw
          ;;
      esac
    done

    printf '\n' >&3
    printf '%s\n' "$password"
  '';
}
