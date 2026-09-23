{ pkgs, config, lib, ... }:

let
  # The disk device - defined in hardware.nix
  bootDisk = config.disko.devices.disk.main.device;

  # The EFI System Partition mount point
  efiMount = config.boot.loader.efi.efiSysMountPoint;

  # Root filesystem type - populated by disko
  rootFsType = config.fileSystems."/".fsType;

  # Root subvolume name - disko automatically appends "subvol=<name>" to options
  _rootMountOpts = config.fileSystems."/".options;
  _rootSubvolOpt = lib.findFirst (lib.hasPrefix "subvol=") null _rootMountOpts;
  rootSubvol      = if _rootSubvolOpt != null
                    then lib.removePrefix "subvol=" _rootSubvolOpt
                    else throw "boot.nix: subvol= not found in fileSystems.\"/\".options";

  # Keep this many Finix generations in NVRAM
  keepGenerations = 3;

  # ── EFISTUB install hook ───────────────────────────────────────────────────

    efistubHook = pkgs.writeShellScript "efistub-install" ''
      set -euo pipefail

      # ── Paths & metadata ──────────────────────────────────────────────────────

      BOOTSPEC="$1/boot.json"
      BOOT_DIR="${efiMount}/EFI/nixos"
      EFISTUBMGR="${pkgs.efistubmgr}/bin/efistubmgr"

      TIMESTAMP=$(${pkgs.coreutils}/bin/date +%s)
      HUMAN_DATE=$(
        ${pkgs.coreutils}/bin/date -d "@$TIMESTAMP" '+%Y-%m-%d %H:%M:%S %Z'
      )

      KERNEL_PATH="$BOOT_DIR/kernel-$TIMESTAMP.efi"
      INITRD_PATH="$BOOT_DIR/initrd-$TIMESTAMP"

      # ── Helpers ───────────────────────────────────────────────────────────────

      get_rev() {
        local target="$1"
        local path="$2"
        local link

        for link in /nix/var/nix/profiles/system-*-link; do
          [ -e "$link" ] || continue

          case "$(readlink "$link")" in
            "$target"|"$path")
              printf '%s\n' "$link" |
                ${pkgs.gnugrep}/bin/grep -oE 'system-[0-9]+-link' |
                ${pkgs.gnugrep}/bin/grep -oE '[0-9]+' |
                ${pkgs.gawk}/bin/awk '{print "rev. " $1}'
              return
              ;;
          esac
        done
      }

      is_kept_timestamp() {
        local needle="$1"

        for ts in "''${KEEP_TIMESTAMPS[@]}"; do
          [ "$ts" = "$needle" ] && return 0
        done

        return 1
      }

      is_seen_timestamp() {
        local needle="$1"

        for ts in "''${ORPHAN_TIMESTAMPS[@]}"; do
          [ "$ts" = "$needle" ] && return 0
        done

        return 1
      }

      # ── Validate & read bootspec ──────────────────────────────────────────────

      [ -r "$BOOTSPEC" ] ||
        { echo "ERROR: boot.json not found at $BOOTSPEC"; exit 1; }

      [ -b "${bootDisk}" ] ||
        { echo "ERROR: boot device not found: ${bootDisk}"; exit 1; }

      KERNEL=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".kernel' "$BOOTSPEC")
      INITRD=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".initrd' "$BOOTSPEC")
      INIT=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".init' "$BOOTSPEC")
      PARAMS=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".kernelParams | join(" ")' "$BOOTSPEC")
      LABEL=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".label // empty' "$BOOTSPEC")
      TOPLEVEL=$(${pkgs.jq}/bin/jq -r '."org.nixos.bootspec.v1".toplevel // empty' "$BOOTSPEC")

      [ -z "$LABEL" ] || [ "$LABEL" = "null" ] && LABEL="Finix"
      [ -z "$TOPLEVEL" ] && TOPLEVEL="$1"

      REV=$(get_rev "$TOPLEVEL" "$1")
      DESCRIPTION="$LABEL''${REV:+ $REV} ❖ $HUMAN_DATE"

      # ── Install kernel & initrd ───────────────────────────────────────────────

      mkdir -p "$BOOT_DIR"

      echo "==> Installing kernel and initrd (timestamp: $TIMESTAMP)"
      install -m 0644 "$KERNEL" "$KERNEL_PATH"
      install -m 0644 "$INITRD" "$INITRD_PATH"

      # ── Secure Boot ───────────────────────────────────────────────────────────

      if [ -d /etc/secureboot/keys ]; then
        echo "==> sbctl: signing kernel"
        ${pkgs.sbctl}/bin/sbctl sign "$KERNEL_PATH" || \
          echo "WARNING: sbctl signing failed, but continuing (Secure Boot may not work)"
      fi

      # ── Create NVRAM entry ────────────────────────────────────────────────────

      echo "==> Creating new primary entry: $DESCRIPTION (timestamp $TIMESTAMP)"

      NEW_ID=$("$EFISTUBMGR" create "${efiMount}" \
        '\EFI\nixos\kernel-'"$TIMESTAMP"'.efi' \
        "$DESCRIPTION" \
        "initrd=\EFI\nixos\initrd-$TIMESTAMP init=$INIT $PARAMS" \
        --timestamp "$TIMESTAMP")

      echo "==> Created Boot$NEW_ID"

      # ── Keep newest generations ───────────────────────────────────────────────

      mapfile -t GENERATIONS < <("$EFISTUBMGR" list)
      echo "==> ''${#GENERATIONS[@]} finix generation(s) in NVRAM"

      KEEP_TIMESTAMPS=()
      for line in "''${GENERATIONS[@]:0:${toString keepGenerations}}"; do
        KEEP_TIMESTAMPS+=(
          "$(${pkgs.gawk}/bin/awk '{print $2}' <<<"$line")"
        )
      done

      declare -A PRUNE_IDS

      if [ "''${#GENERATIONS[@]}" -gt "${toString keepGenerations}" ]; then
        for line in "''${GENERATIONS[@]:${toString keepGenerations}}"; do
          id=$(${pkgs.gawk}/bin/awk '{print $1}' <<<"$line")
          ts=$(${pkgs.gawk}/bin/awk '{print $2}' <<<"$line")

          "$EFISTUBMGR" delete "$id"
          PRUNE_IDS["$ts"]="$id"
        done
      fi

      # ── Remove orphaned ESP files ─────────────────────────────────────────────

      ORPHAN_TIMESTAMPS=()

      for f in "$BOOT_DIR"/kernel-*.efi "$BOOT_DIR"/initrd-*; do
        [ -e "$f" ] || continue

        base=$(basename "$f")
        file_ts="''${base#*-}"
        file_ts="''${file_ts%.efi}"

        if ! is_kept_timestamp "$file_ts" &&
           ! is_seen_timestamp "$file_ts"; then
          ORPHAN_TIMESTAMPS+=("$file_ts")
        fi
      done

      for ts in "''${ORPHAN_TIMESTAMPS[@]}"; do
        if [ -n "''${PRUNE_IDS[$ts]:-}" ]; then
          echo "==> Removing orphaned ESP files kernel-$ts.efi + initrd-$ts" \
            "(ts $ts, removed matching Boot''${PRUNE_IDS[$ts]} NVRAM entry)"
        else
          echo "==> Removing orphaned ESP files kernel-$ts.efi + initrd-$ts" \
            "(ts $ts, no matching NVRAM entry)"
        fi

        rm -f "$BOOT_DIR/kernel-$ts.efi" "$BOOT_DIR/initrd-$ts"
      done

      echo "==> EFISTUB setup complete"
    '';
in
{
  # Plain LTS kernel - this box just routes/serves, no need for -zen's desktop tuning.
  boot.kernelPackages = pkgs.linuxPackages;

  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  boot.loader.script = {
    enable = true;
    installHook = efistubHook;
  };

  boot.initrd = {
    availableKernelModules = [
      "ahci"       # M.2 SATA SSD
      "xhci_pci"
      "usb_storage"
      "sd_mod"
    ];

    supportedFilesystems.btrfs.enable = true;
  };

  # AMD Jaguar-based SoC (GX-420GI) - has AMD-V, useful once containers/VMs land.
  boot.kernelModules = [ "kvm-amd" ];

  boot.kernelParams = [
    "rootflags=subvol=${rootSubvol}"
    "rootfstype=${rootFsType}"
    "zswap.enabled=0"
  ];
}
