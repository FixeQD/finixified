{ config, pkgs, ... }:
let
  user = config.modules.user.name;
in
{
  sops.age.keyFile = "/etc/sops/age/keys.txt";
  sops.defaultSopsFile = ../../home/secrets.yaml;

  environment.systemPackages = [ pkgs.sops ];

  sops.secrets = {
    gh_gpg = {
      owner = user;
      mode = "0400";
    };
  };
}
