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
  imports = [ sops-nix.finixModules.sops ];

  # the installer puts both keys here by decrypting secrets/age/*.age
  # keys.txt contains both the host and infra identities
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
    tailscale_oauth_secret.mode = "0400";
    netbird_key = {
      sopsFile = ../../secrets/infra.yaml;
      mode = "0400";
    };
  };
}
