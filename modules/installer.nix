{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.installer;
  q = lib.escapeShellArg;

  hostname = config.networking.hostName;

  chrootPersistDir = lib.removePrefix "/mnt" cfg.persistDir;
  passwdDir = "${cfg.persistDir}/user-passwords";
  ageKeyDir = "${cfg.persistDir}/sops/age";
  ageKeyFile = "${ageKeyDir}/keys.txt";
  passwdFile = user: "${passwdDir}/${user}";

  askpass = lib.getExe (pkgs.callPackage ./helpers/askpass.nix { });
  sbctl = lib.getExe pkgs.sbctl;

  renderStep =
    total: index:
    {
      title,
      run,
      skipWhen ? null,
      skipTitle ? title,
      always ? "",
      ...
    }:
    let
      header = msg: "echo ${q "==> [${toString index}/${toString total}] ${msg}"}";
    in
    if skipWhen == null then
      ''
        ${header title}
        ${run}
        ${always}
      ''
    else
      ''
        if ${skipWhen}; then
          ${header skipTitle}
        else
          ${header title}
          ${run}
        fi
        ${always}
      '';

  mkInstaller =
    {
      resume ? false,
    }:
    let
      diskoMode = if resume then "mount" else "destroy,format,mount";
      diskoScript =
        if resume then
          "${config.system.build.mount}/bin/disko-mount"
        else
          "${config.system.build.destroyFormatMount}/bin/disko-destroy-format-mount";

      installSource =
        if cfg.prebuilt then
          "--system ${q "${config.system.build.toplevel}"}"
        else
          ''--flake "$flake_dir"${q "#${hostname}"}'';

      passwordsExist = lib.concatMapStringsSep " && " (u: "[ -s ${q (passwdFile u)} ]") cfg.passwordUsers;

      setPassword = user: ''
        password="$(ask_password ${q user})"
        mkpasswd -m sha-512 -s <<< "$password" > ${q (passwdFile user)}
        chmod 600 ${q (passwdFile user)}
        unset password
      '';

      steps = lib.filter (s: s.enable or true) [
        {
          title = "disko (mode: ${diskoMode}) for host '${hostname}'";
          run = ''
            ${q diskoScript}

            echo "    initializing persistent directories and machine-id"
            mkdir -p ${q "${cfg.persistDir}/var/lib/dbus"}
            mkdir -p ${q ageKeyDir} ${q passwdDir}
            chmod 700 ${q ageKeyDir} ${q passwdDir}
            dbus-uuidgen --ensure=${q "${cfg.persistDir}/machine-id"}
          '';
        }

        {
          title = "passwords: setting passwords for ${lib.concatStringsSep ", " cfg.passwordUsers}";
          skipWhen = if resume then passwordsExist else null;
          skipTitle = "passwords: existing password files found, skipping";
          run = ''
            (
              umask 077
              ${lib.concatMapStrings setPassword cfg.passwordUsers}
            )
          '';
          always = ''
            echo "    linking password files into the installation root"
            mkdir -p /mnt/etc
            ln -sfT ${q "${chrootPersistDir}/user-passwords"} /mnt/etc/user-passwords
          '';
        }

        {
          enable = cfg.requireSops;
          title = "sops: decrypting host age key with the FIDO2 token";
          run = ''
            host_key_blob="$flake_dir/secrets/host-age-key.age"
            fido2_identity="$flake_dir/secrets/fido2-identity.txt"
            installed_age_key=false

            decrypt_age_key() {
              for required_file in "$host_key_blob" "$fido2_identity"; do
                [ -f "$required_file" ] || die "$required_file not found"
              done

              echo "    plug in the token and touch it when it blinks"
              if ! (
                umask 077
                age --decrypt \
                  --identity "$fido2_identity" \
                  --output ${q ageKeyFile} \
                  "$host_key_blob"
              ); then
                rm -f ${q ageKeyFile}
                die "could not decrypt $host_key_blob with the FIDO2 token"
              fi
              chmod 600 ${q ageKeyFile}
            }

            ${
              if resume then
                ''
                  if [ -s ${q ageKeyFile} ]; then
                    echo "    age key already present, skipping installation"
                  else
                    installed_age_key=true
                    decrypt_age_key
                  fi
                ''
              else
                ''
                  installed_age_key=true
                  decrypt_age_key
                ''
            }

            echo "    verifying key by decrypting secrets/secrets.yaml..."
            if SOPS_AGE_KEY_FILE=${q ageKeyFile} sops -d "$flake_dir/secrets/secrets.yaml" >/dev/null; then
              echo "    OK - key decrypts secrets.yaml successfully."
            else
              echo "    FAILED - this key cannot decrypt $flake_dir/secrets/secrets.yaml" >&2
              grep -h '^# public key:' ${q ageKeyFile} >&2 || true
              grep -h 'recipient:' "$flake_dir/secrets/secrets.yaml" >&2 || true
              if [ "$installed_age_key" = "true" ]; then
                rm -f ${q ageKeyFile}
              fi
              exit 1
            fi
          '';
        }

        {
          title = "nixos-install";
          run = ''
            nixos-install \
              ${installSource} \
              --no-root-passwd \
              --no-channel-copy
          '';
        }

        {
          title = "sbctl: creating Secure Boot keys";
          run = ''
            ${lib.optionalString (chrootPersistDir != "") ''
              mkdir -p ${q "${cfg.persistDir}/var/lib/sbctl"} /mnt/var/lib
              ln -sfT ${q "${chrootPersistDir}/var/lib/sbctl"} /mnt/var/lib/sbctl
            ''}
            nixos-enter --root /mnt -c ${q "${sbctl} create-keys"}
          '';
        }
      ];

      prelude = ''
        die() {
          echo "ERROR: $*" >&2
          exit 1
        }

        ask_password() {
          local label="$1" pass pass2
          while true; do
            pass="$(${askpass} "    password for $label: ")" \
              || die "could not ask for a password (no display and no tty)"
            pass2="$(${askpass} "    confirm password for $label: ")" \
              || die "could not ask for a password (no display and no tty)"
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

        ${lib.optionalString (cfg.requireSops || !cfg.prebuilt) ''flake_dir="$(pwd)"''}
      '';
    in
    pkgs.writeShellApplication {
      name = "${lib.optionalString resume "resume-"}install-${hostname}";

      runtimeInputs = [
        pkgs.coreutils
        pkgs.dbus
        pkgs.mkpasswd
        pkgs.nixos-enter
        pkgs.nixos-install
      ]
      ++ lib.optionals cfg.requireSops [
        pkgs.age
        pkgs.age-plugin-fido2-hmac
        pkgs.sops
      ];

      text = lib.concatStringsSep "\n" (
        [ prelude ] ++ lib.imap1 (renderStep (lib.length steps)) steps ++ [ ''echo "==> Ready!"'' ]
      );

      meta.description = "${if resume then "Resume installation" else "Install"} for ${hostname}";
    };
in
{
  options.modules.installer = {
    requireSops = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the host installer requires SOPS setup.";
    };

    prebuilt = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install the system closure built by this flake (nixos-install --system) instead of letting nixos-install evaluate and build it from the flake.";
    };

    persistDir = lib.mkOption {
      type = lib.types.str;
      default = if builtins.hasAttr "/persist" config.fileSystems then "/mnt/persist" else "/mnt";
      description = "Where the installer keeps persistent state (passwords, age key, machine-id) while /mnt is mounted.";
    };

    passwordUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        config.modules.user.name
        "root"
      ];
      description = "Users the installer asks a password for.";
    };
  };

  config.system.build = {
    installer = mkInstaller { };
    resumeInstaller = mkInstaller { resume = true; };
  };
}
