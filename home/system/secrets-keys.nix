{ config, osConfig, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
    };
  };

  # home.file.".ssh/id_ed25519_gh" = {
  #   source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.secrets.auth_key_1.path;
  # };

  # home.file.".ssh/id_ed25519_gh.pub" = {
  #   source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.secrets.auth_key_2.path;
  # };

  programs.gpg = {
    enable = true;
    settings = {
      personal-digest-preferences = "SHA256";
      cert-digest-algo = "SHA256";
      default-preference-list = "SHA256 SHA1 MD5";
      keyid-format = "0xlong";
      with-fingerprint = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
  };

  home.activation.importGpgKey = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ -r "${osConfig.sops.secrets.gh_gpg.path}" ]; then
      ${pkgs.gnupg}/bin/gpg --batch --import "${osConfig.sops.secrets.gh_gpg.path}" 2>/dev/null || true
      ${pkgs.gnupg}/bin/gpg --batch --export 14B42F47A55383DE | ${pkgs.gnupg}/bin/gpg --batch --import 2>/dev/null || true
    fi
  '';

  home.activation.fixGnupgPerms = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "${config.home.homeDirectory}/.gnupg" ]; then
      chmod 700 "${config.home.homeDirectory}/.gnupg"
      find "${config.home.homeDirectory}/.gnupg" -type f -exec chmod 600 {} \;
      find "${config.home.homeDirectory}/.gnupg" -type d -exec chmod 700 {} \;
    fi
  '';

  programs.git.settings = {
    user.signingKey = "14B42F47A55383DE";
    commit.gpgsign = true;
    tag.gpgsign = true;
  };
}
