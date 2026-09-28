{
  pkgs,
  ...
}:
let
  yaml = pkgs.formats.yaml { };
in
{
  xdg.config.files."gh/config.yml".source = yaml.generate "gh-config.yml" {
    git_protocol = "https";
    prompt = "enabled";
  };
  packages = [ pkgs.gh ];
}
