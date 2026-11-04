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
        email = "git@fixeq.dev";
        signingKey = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIAwS91Ild0iX3vtM81mXpwtT31TPh7SrPKdRUiDSDoZeAAAAD3NzaDpnaXQtc2lnbmluZw== Paweł (FIDO Git Signing) <git@fixeq.dev>";
      };
      gpg.format = "ssh";
      commit.gpgsign = true;
      tag.gpgsign = true;
      credential = {
        "https://github.com".helper = [
          ""
          "${pkgs.gh}/bin/gh auth git-credential"
        ];
        "https://gist.github.com".helper = [
          ""
          "${pkgs.gh}/bin/gh auth git-credential"
        ];
      };
    };
  };
}
