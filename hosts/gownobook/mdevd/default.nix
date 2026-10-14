{ pkgs, lib, ... }:

let
  applyScript = pkgs.writeShellScript "mdevd-no-turbo-power" ''
    target=/sys/devices/system/cpu/intel_pstate/no_turbo
    [ -w "$target" ] || exit 0

    online=
    for supply in /sys/class/power_supply/*; do
      [ -f "$supply/online" ] || continue
      [ "$(cat "$supply/type" 2>/dev/null)" = Mains ] || continue
      online=$(cat "$supply/online" 2>/dev/null) || online=
      [ -n "$online" ] && break
    done
    [ -n "$online" ] || exit 0

    if [ "$online" = 1 ]; then want=0; else want=1; fi

    current=$(cat "$target" 2>/dev/null) || exit 0
    [ "$current" = "$want" ] && exit 0

    if echo "$want" >"$target" 2>/dev/null; then
      logger -t no-turbo-power "''${MDEV:-start} adapter=$online -> no_turbo=$want"
    else
      logger -t no-turbo-power "''${MDEV:-start} write no_turbo=$want rejected - bit 38 of MSR_IA32_MISC_ENABLE (0x1A0) is set by firmware"
    fi

    exit 0
  '';
in
{
  services.mdevd.hotplugRules = lib.mkAfter "-DEVTYPE=power_supply;.* root:root 0600 *${applyScript}";

  finit.run.no-turbo-power = {
    description = "set no_turbo from AC adapter state";
    command = "${applyScript}";
    runlevel = "S";
    conditions = "service/mdevd/ready";
    cgroup.init = { };
    log = { };
  };
}
