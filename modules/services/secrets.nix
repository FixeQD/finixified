{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.modules.user.name;
  gpgKeyId = "14B42F47A55383DE";

  hjemEnabled = lib.any (u: u.enable && u.user == user) (lib.attrValues config.hjem.users);
in
{
  imports = [ ../sops ];

  sops.age.keyFile = "/etc/sops/age/keys.txt";
  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  environment.systemPackages = [ pkgs.sops ];

  sops.secrets = {
    gh_gpg = {
      owner = user;
      mode = "0400";
    };

    gownobook_cloudflared_token = {
      owner = user;
      mode = "0400";
    };
  };

  finit.tasks = lib.optionalAttrs hjemEnabled {
    gpg-import-gh-key = {
      description = "Import the GitHub signing key from the sops secret";
      user = user;
      conditions = [ "task/hjem-activate-${user}/success" ];

      command = pkgs.writeShellScript "gpg-import-gh-key" ''
        set -eu

        secret="${config.sops.secrets.gh_gpg.path}"
        gnupg_home="${config.users.users.${user}.home}/.gnupg"
        gpg_opts="--batch --no-tty --quiet --pinentry-mode error"

        [ -r "$secret" ] || exit 0

        if GNUPGHOME="$gnupg_home" ${pkgs.gnupg}/bin/gpg $gpg_opts --with-colons \
             --list-secret-keys "${gpgKeyId}" >/dev/null 2>&1
        then
          exit 0
        fi

        GNUPGHOME="$gnupg_home" ${pkgs.gnupg}/bin/gpg $gpg_opts --import "$secret" \
          >/dev/null 2>&1 || true

        GNUPGHOME="$gnupg_home" ${pkgs.gnupg}/bin/gpg $gpg_opts --export "${gpgKeyId}" \
          | GNUPGHOME="$gnupg_home" ${pkgs.gnupg}/bin/gpg $gpg_opts --import \
          >/dev/null 2>&1 || true
      '';
    };
  };
}
