{ ... }:
{
  programs.fish = {
    enable    = true;
    generateCompletions = false;
    functions.fish_greeting = "fastfetch";
    shellInit = ''
      set -gx GPG_TTY (tty)
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase        = false;
      user.name          = "Paweł";
      user.email         = "github@fixeq.qzz.io";
    };
  };
}
