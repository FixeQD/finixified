{ config, lib, mkMdevHelper, pkgs, ... }:
let
  libfido2 = pkgs.fetchFromGitHub {
    owner = "Yubico";
    repo = "libfido2";
    rev = "1c79d1c3ac8e6efeee41c5a63d4d8eb7e4157b03";
    hash = "sha256-CjkamEd4O2PhLYD6f9PEW50p3F1n+Jeie2iW5G2l6Ec=";
  };

  fidoMdevRule = mkMdevHelper {
    name = "fido-mdev-rule";
    source = "${libfido2}/udev/70-u2f.rules";
    group = "fido";
    match = "SUBSYSTEM=hidraw;.*";
    setup = ''
      hid_id=
      while IFS= read -r line; do
        case "$line" in
          HID_ID=*)
            hid_id="''${line#HID_ID=}"
            break
            ;;
        esac
      done < "/sys/class/hidraw/$MDEV/device/uevent"
    '';
    caseExpression = "\"$hid_id\"";
    collect = ''
      for clauses in rules:
          vendor = next(
              (
                  clause.value.lower()
                  for clause in clauses
                  if (
                      clause.key == "ATTRS"
                      and clause.attribute == "idVendor"
                      and clause.operator == "=="
                  )
              ),
              None,
          )
          product = next(
              (
                  clause.value.lower()
                  for clause in clauses
                  if (
                      clause.key == "ATTRS"
                      and clause.attribute == "idProduct"
                      and clause.operator == "=="
                  )
              ),
              None,
          )
          if vendor is not None and product is not None:
              devices.add(f"0000{vendor.upper()}:0000{product.upper()}")
    '';
  };
in
{
  config = lib.mkIf config.modules.mdevd.enable {
    users.groups.fido = { };

    services.mdevd.hotplugRules = lib.mkBefore fidoMdevRule;
  };
}
