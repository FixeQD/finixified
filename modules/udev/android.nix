{
  config,
  lib,
  pkgs,
  ...
}:
let
  androidUdevRules = pkgs.fetchFromGitHub {
    owner = "M0Rf30";
    repo = "android-udev-rules";
    rev = "f45ef6c7716ee40056fa687aeac18a8ca40933aa";
    hash = "sha256-eEMCPkYp0GlBXcd+WhojITqSHzGhj7uB6GR7SYuyArg=";
  };

  androidRules = pkgs.runCommandLocal "android-udev-rules" { } ''
    install -D ${androidUdevRules}/51-android.rules $out/lib/udev/rules.d/51-android.rules
  '';
in
{
  config = lib.mkIf config.modules.udev.enable {
    users.groups.adbusers = { };

    services.udev.packages = [ androidRules ];
  };
}
