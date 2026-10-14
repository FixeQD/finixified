{ ... }:
{
  rum.programs.fish = {
    enable = true;
    abbrs = {
      ll = "eza -la --git";
      l = "eza -l --git";
      t = "eza --tree";
      c = "bat --paging=never";
      gst = "git status";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate -20";
    };
    aliases = {
      ex = "exit";
      vi = "nvim";
      cat = "bat --paging=never";
      fd = "fd --type f";
      find = "fd";
      top = "btop";
    };
    functions = {
      fish_greeting = ''
        history max=50000
        fastfetch
      '';
      gpg-tty = ''
        set -gx GPG_TTY (tty)
      '';
    };
    config = ''
      set -e fish_history
      set -gx GPG_TTY (tty)
    '';
  };
}
