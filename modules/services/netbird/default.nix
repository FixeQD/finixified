{
  finix,
  ...
}:
{
  imports = [
    finix.nixosModules.chronyd
    ./options.nix
    ./service.nix
    ./firewall.nix
  ];
}
