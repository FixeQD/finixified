{ pkgs, lib, config, finix, ... }:
with lib;
let
  cfg = config.modules.audio;
  pipewire = config.programs.pipewire.package;
  wireplumber = config.programs.wireplumber.package;
in {
  imports = [
    finix.nixosModules.pipewire
    finix.nixosModules.sessiond-hooks
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

    services.sessiond-hooks = {
      enable = true;
      hooks = {
        pipewire.settings = {
          on_start = "${pipewire}/bin/pipewire";
          restart = {
            on = "Always";
            delay = 2;
          };
        };

        pipewire-pulse.settings = {
          on_start = "${pipewire}/bin/pipewire-pulse";
          restart = {
            on = "Always";
            delay = 2;
          };
        };

        wireplumber.settings = {
          on_start = "${wireplumber}/bin/wireplumber";
          restart = {
            on = "Always";
            delay = 2;
          };
        };
      };
    };
  };
}
