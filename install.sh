#!/usr/bin/env bash
# DISKO_BIN / SBCTL_BIN / MKPASSWD_BIN / FLAKE_HOST / PRIMARY_USER / REQUIRE_SOPS.

set -euo pipefail

: "${DISKO_BIN:?DISKO_BIN must be set}"
: "${SBCTL_BIN:?SBCTL_BIN must be set}"
: "${MKPASSWD_BIN:?MKPASSWD_BIN must be set}"
: "${PRIMARY_USER:?PRIMARY_USER must be set}"
: "${FLAKE_HOST:=gownobook}"
: "${DISKO_MODE:=destroy,format,mount}"
# : "${REQUIRE_SOPS:=true}"

FLAKE_DIR="$(pwd)"

echo "==> [1/5] disko (mode: $DISKO_MODE) for host '$FLAKE_HOST'"
"$DISKO_BIN" \
  --mode "$DISKO_MODE" \
  --flake "$FLAKE_DIR#$FLAKE_HOST"

echo "==> [2/5] passwords: setting passwords for $PRIMARY_USER and root"
PASSWD_DIR="/mnt/etc/nixos-passwords"
mkdir -p "$PASSWD_DIR"
chmod 700 "$PASSWD_DIR"

read_password_masked() {
  local prompt="$1" password="" char=""

  redraw_masked_prompt() {
    local stars=""
    if [ "${#password}" -gt 0 ]; then
      stars="$(printf '%*s' "${#password}" '' | tr ' ' '*')"
    fi
    printf '\r\033[K%s%s' "$prompt" "$stars" >&2
  }

  redraw_masked_prompt
  stty -echo
  trap 'stty echo' RETURN

  while IFS= read -r -s -n1 char; do
    if [ -z "$char" ]; then
      break
    fi

    case "$char" in
      $'\177'|$'\b')
        if [ -n "$password" ]; then
          password="${password%?}"
          redraw_masked_prompt
        fi
        ;;
      $'\e')
        # Discard the rest of escape sequences
        IFS= read -r -s -n2 -t 0.01 _ || true
        ;;
      *)
        password+="$char"
        redraw_masked_prompt
        ;;
    esac
  done

  stty echo
  trap - RETURN
  echo >&2
  printf '%s' "$password"
}

ask_password() {
  local label="$1" pass pass2
  while true; do
    pass="$(read_password_masked "    password for $label: ")"
    pass2="$(read_password_masked "    confirm password for $label: ")"
    if [ -z "$pass" ]; then
      echo "    empty password, try again" >&2
      continue
    fi
    if [ "$pass" = "$pass2" ]; then
      printf '%s' "$pass"
      return
    fi
    echo "    passwords don't match, try again" >&2
  done
}

(
  umask 077
  for label_user in "$PRIMARY_USER" "root"; do
    password="$(ask_password "$label_user")"
    "$MKPASSWD_BIN" -m sha-512 -s <<< "$password" > "$PASSWD_DIR/$label_user"
    chmod 600 "$PASSWD_DIR/$label_user"
    unset password
  done
)

# if [ "$REQUIRE_SOPS" = "true" ]; then
#   echo "==> [3/5] sops: installing age key"
#   AGE_KEY_DIR="/mnt/etc/sops/age"
#   mkdir -p "$AGE_KEY_DIR"
#   chmod 700 "$AGE_KEY_DIR"
#
#   run_sops() {
#     if command -v sops >/dev/null 2>&1; then
#       sops "$@"
#     else
#       nix --extra-experimental-features 'nix-command flakes' run nixpkgs#sops -- "$@"
#     fi
#   }
#
#   DEFAULT_KEY_PATH="$HOME/.config/sops/age/keys.txt"
#   printf '    path to age key file [%s]: ' "$DEFAULT_KEY_PATH" >&2
#   read -r KEY_PATH
#   KEY_PATH="${KEY_PATH:-$DEFAULT_KEY_PATH}"
#
#   (
#     umask 077
#     if [ -f "$KEY_PATH" ]; then
#       cp "$KEY_PATH" "$AGE_KEY_DIR/keys.txt"
#       echo "    copied from $KEY_PATH"
#     else
#       echo "    '$KEY_PATH' not found - falling back to manual paste"
#       printf  "    Paste age private key, then Ctrl+D: "
#       stty -echo
#       trap 'stty echo' EXIT
#       : > "$AGE_KEY_DIR/keys.txt"
#       while IFS= read -r line; do
#         printf '*'
#         printf '%s\n' "$line" >> "$AGE_KEY_DIR/keys.txt"
#       done
#       stty echo
#       trap - EXIT
#       echo
#       echo "    ($(wc -l < "$AGE_KEY_DIR/keys.txt") lines written)"
#     fi
#     chmod 600 "$AGE_KEY_DIR/keys.txt"
#   )
#
#   echo "    verifying key by decrypting home/secrets.yaml..."
#   if SOPS_AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt" run_sops -d "$FLAKE_DIR/home/secrets.yaml" >/dev/null; then
#     echo "    OK - key decrypts secrets.yaml successfully."
#   else
#     echo "    FAILED - this key cannot decrypt $FLAKE_DIR/home/secrets.yaml" >&2
#     rm -f "$AGE_KEY_DIR/keys.txt"
#     exit 1
#   fi
# else
#   echo "==> [3/5] sops: skipped (REQUIRE_SOPS=false, host has no sops secrets)"
# fi

echo "==> [4/5] nixos-install"
nixos-install \
  --flake "$FLAKE_DIR#$FLAKE_HOST" \
  --no-root-passwd \
  --no-channel-copy

echo "==> [5/5] sbctl: creating Secure Boot keys"
nixos-enter --root /mnt -c "'$SBCTL_BIN' create-keys"

echo "==> Ready!"
