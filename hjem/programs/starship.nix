{
  lib,
  ...
}:
{
  rum.programs.starship = {
    enable = true;
    settings = {
      palette = "tokyo_night";
      format = lib.removeSuffix "\n" ''
        $os$directory$git_branch$git_state$fill$git_status$cmd_duration$time
        $character
      '';
      right_format = "";
      add_newline = true;
      c.disabled = true;
      cmake.disabled = true;
      haskell.disabled = true;
      python.disabled = true;
      ruby.disabled = true;
      rust.disabled = true;
      perl.disabled = true;
      package.disabled = true;
      lua.disabled = true;
      nodejs.disabled = true;
      java.disabled = true;
      golang.disabled = true;
      conda.disabled = true;
      os = {
        disabled = false;
        format = "[$symbol]($style) ";
        style = "fg:overlay";
        symbols = {
          Arch = " ";
          Linux = " ";
        };
      };
      directory = {
        format = "[$path]($style)[$read_only]($read_only_style) ";
        style = "fg:lavender bold";
        read_only = " 󰌾";
        read_only_style = "fg:red";
        truncation_length = 4;
        truncate_to_repo = false;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙";
          "Downloads" = "󰇚";
          "Pictures" = "󰉏";
          "Music" = "󰎆";
          "Videos" = "󰕧";
          "Desktop" = "󰇘";
          "~" = "~";
        };
      };
      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style) ";
        symbol = " ";
        style = "fg:green";
        truncation_length = 20;
      };
      git_state = {
        format = "[$state($progress_current/$progress_total)]($style) ";
        style = "fg:yellow bold";
      };
      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "fg:yellow";
        conflicted = "󰞇 ";
        ahead = "󰁝\${count} ";
        behind = "󰁅\${count} ";
        diverged = "󰹺 ";
        up_to_date = "";
        untracked = "󰋗\${count} ";
        stashed = "󰏗 ";
        modified = "󰏭\${count} ";
        staged = "󰐕\${count} ";
        renamed = "󰑕\${count} ";
        deleted = "󰆴\${count} ";
      };
      fill.symbol = " ";
      time = {
        disabled = false;
        format = "[$time]($style) ";
        style = "fg:overlay";
        time_format = "%H:%M";
        use_12hr = false;
      };
      cmd_duration = {
        min_time = 1;
        format = "[󱦟 $duration]($style) ";
        style = "fg:peach";
        disabled = false;
      };
      character = {
        success_symbol = "[❯](fg:mauve bold)";
        error_symbol = "[❯](fg:red bold)";
        vicmd_symbol = "[❮](fg:green bold)";
      };
      palettes.tokyo_night = {
        red = "#f7768e";
        green = "#9ece6a";
        yellow = "#e0af68";
        peach = "#ff9e64";
        mauve = "#bb9af7";
        lavender = "#7aa2f7";
        sky = "#7dcfff";
        text = "#c0caf5";
        subtext = "#a9b1d6";
        overlay = "#565f89";
        surface = "#292e42";
        base = "#1a1b26";
        crust = "#15161e";
      };
    };
  };
}
