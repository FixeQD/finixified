{
  config,
  pkgs,
  sops-nix,
  ...
}:
let
  user = config.modules.user.name;
in
{
  imports = [ sops-nix.nixosModules.sops ];

  # install.sh puts this file here by decrypting secrets/host-age-key.age
  sops.age.keyFile = "/persist/sops/age/keys.txt";
  sops.age.sshKeyPaths = [ ];
  sops.gnupg.sshKeyPaths = [ ];
  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  environment.systemPackages = [ pkgs.sops ];

  sops.secrets = {
    gownobook_cloudflared_token = {
      owner = user;
      mode = "0400";
    };
  };
}
