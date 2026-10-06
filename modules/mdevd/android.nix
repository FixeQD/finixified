{ config, lib, mkMdevHelper, pkgs, ... }:
let
  androidUdevRules = pkgs.fetchFromGitHub {
    owner = "M0Rf30";
    repo = "android-udev-rules";
    rev = "f45ef6c7716ee40056fa687aeac18a8ca40933aa";
    hash = "sha256-eEMCPkYp0GlBXcd+WhojITqSHzGhj7uB6GR7SYuyArg=";
  };

  androidMdevRule = mkMdevHelper {
    name = "android-mdev-rule";
    source = "${androidUdevRules}/51-android.rules";
    group = "adbusers";
    match = "SUBSYSTEM=usb;DEVTYPE=usb_device;.*";
    caseExpression = "\"$PRODUCT\"";
    collect = ''
      current_vendor: str | None = None
      for clauses in rules:
          for clause in clauses:
              if (
                  clause.key == "ATTR"
                  and clause.attribute == "idVendor"
                  and clause.operator in {"==", "!="}
              ):
                  current_vendor = clause.value.lower()

          products = [
              clause.value.lower()
              for clause in clauses
              if (
                  clause.key == "ATTR"
                  and clause.attribute == "idProduct"
                  and clause.operator == "=="
              )
          ]
          is_android = any(
              (
                  clause.key == "GOTO"
                  and clause.value in {"adb", "user"}
              )
              or clause.value == "android_adb"
              or clause.attribute == "adb_user"
              for clause in clauses
          )
          if current_vendor is None or not is_android:
              continue
          for product in products:
              devices.add(f"{current_vendor}/{product}/*")
    '';
  };
in
{
  config = lib.mkIf config.modules.mdevd.enable {
    users.groups.adbusers = { };

    services.mdevd.hotplugRules = lib.mkBefore androidMdevRule;
  };
}
