FROM nixos/nix:latest

ENV NIX_CONFIG="experimental-features = nix-command flakes"
ENV PATH="/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:${PATH}"

RUN nix profile install \
    nixpkgs#gh \
    nixpkgs#jq \
    nixpkgs#ripgrep \
    nixpkgs#nil \
    nixpkgs#nixd
