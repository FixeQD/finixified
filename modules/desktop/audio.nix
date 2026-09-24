{ pkgs, lib, config, finix, ... }:
with lib;
let cfg = config.modules.audio; in
{
  imports = [
    finix.nixosModules.pipewire
    finix.nixosModules.wireplumber
  ];

  options.modules.audio.enable = mkEnableOption "PipeWire audio (finix programs.pipewire/wireplumber)";

  config = mkIf cfg.enable {
    programs.pipewire.enable = true;
    programs.pipewire.alsa.enable = true;
    programs.wireplumber.enable = true;

    environment.systemPackages = [
      pkgs.pavucontrol
    ];

    environment.etc."profile.d/pipewire-session.sh" = {
      text = ''
        if [ -n "$XDG_RUNTIME_DIR" ] && [ ! -e "$XDG_RUNTIME_DIR/pipewire-session.lock" ]; then
          if ( set -o noclobber; : > "$XDG_RUNTIME_DIR/pipewire-session.lock" ) 2>/dev/null; then
            ${config.programs.pipewire.package}/bin/pipewire >/dev/null 2>&1 &
            ${config.programs.pipewire.package}/bin/pipewire-pulse >/dev/null 2>&1 &
            ${lib.optionalString config.programs.wireplumber.enable "${config.programs.wireplumber.package}/bin/wireplumber >/dev/null 2>&1 &"}
          fi
        fi
      '';
    };
  };
}
