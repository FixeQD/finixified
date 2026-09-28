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
      user = {
        name = "Paweł";
        email = "github@fixeq.qzz.io";
        signingKey = "14B42F47A55383DE";
      };
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
