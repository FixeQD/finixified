{
  pkgs,
  ...
}:
{
  rum.programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = false;

      "depot-tools" = {
        useNewAuthStack = true;
      };

      user = {
        name = "Paweł";
        email = "git@fixeq.qzz.io";
        signingKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHecfiwMw9k6bICGFQ5nEbGbQsOPPVtpjHeEc/7W3kVPAAAAD3NzaDpnaXQtc2lnbmluZw== Paweł (FIDO Git Signing) git@fixeq.qzz.io";
      };
      gpg.format = "ssh";
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
  };
}
