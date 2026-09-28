let
  esc = builtins.fromJSON ''"\u001b"'';
  fg = r: g: b: "${esc}[38;2;${toString r};${toString g};${toString b}m";
  bold = r: g: b: "${esc}[1;38;2;${toString r};${toString g};${toString b}m";
  reset = "${esc}[0m";
  purple = "#bb9af7";
  blue = "#7aa2f7";
in
{
  osConfig,
  ...
}:
{
  rum.programs.fastfetch = {
    enable = true;
    inherit (osConfig.programs.fastfetch) package;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      logo = {
        type = "kitty";
        source = "arch";
        color = {
          "1" = "#f7768e";
          "2" = "#414868";
        };
        padding = {
          top = 1;
          left = 2;
          right = 4;
        };
      };
      display = {
        separator = "  ";
        color = {
          keys = purple;
          title = purple;
        };
      };
      modules = [
        {
          type = "title";
          format = "${bold 187 154 247}{user-name}${reset}${fg 86 95 137}@${reset}${bold 122 162 247}{host-name}${reset}";
        }
        "separator"
        {
          type = "os";
          key = "  OS";
          keyColor = purple;
        }
        {
          type = "kernel";
          key = "  Kernel";
          keyColor = blue;
        }
        {
          type = "uptime";
          key = " 󰅐  Uptime";
          keyColor = purple;
        }
        {
          type = "packages";
          key = " 󰏖  Pakiete";
          keyColor = blue;
        }
        {
          type = "shell";
          key = "  Shell";
          keyColor = purple;
        }
        {
          type = "display";
          key = " 󰍹  Ekran";
          keyColor = blue;
        }
        {
          type = "wm";
          key = "  WM";
          keyColor = purple;
        }
        {
          type = "terminal";
          key = "  Terminal";
          keyColor = blue;
        }
        {
          type = "cursor";
          key = " 󰳿  Kursor";
          keyColor = purple;
        }
        {
          type = "theme";
          key = "  Motyw";
          keyColor = blue;
        }
        {
          type = "icons";
          key = "  Ikony";
          keyColor = purple;
        }
        "break"
        {
          type = "cpu";
          key = "  CPU";
          keyColor = blue;
        }
        {
          type = "gpu";
          key = " 󰾲  GPU";
          keyColor = purple;
          index = "all";
        }
        {
          type = "memory";
          key = " 󰍛  RAM";
          keyColor = blue;
        }
        {
          type = "disk";
          key = " 󰋊  Dysk";
          keyColor = purple;
          folders = "/";
        }
        {
          type = "battery";
          key = " 󰁹  Bateria";
          keyColor = blue;
        }
        "break"
        {
          type = "colors";
          symbol = "circle";
          paddingLeft = 2;
        }
      ];
    };
  };
}
