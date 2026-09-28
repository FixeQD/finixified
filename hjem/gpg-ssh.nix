{
  lib,
  pkgs,
  ...
}:
{
  files.".ssh/config".text = ''
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
  '';
  packages = [ pkgs.openssh pkgs.gnupg ];
  files.".gnupg" = {
    type = "directory";
    permissions = "0700";
  };
  files.".gnupg/gpg.conf".text = ''
    personal-digest-preferences SHA256
    cert-digest-algo SHA256
    default-preference-list SHA256 SHA1 MD5
    keyid-format 0xlong
    with-fingerprint
  '';
  files.".gnupg/gpg-agent.conf".text = ''
    pinentry-program ${lib.getExe pkgs.pinentry-qt}
    enable-ssh-support
    default-cache-ttl 3600
    max-cache-ttl 7200
  '';
}
