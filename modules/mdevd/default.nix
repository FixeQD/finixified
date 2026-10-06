{ lib, pkgs, ... }:
let
  udevGrammar = pkgs.tree-sitter.buildGrammar {
    language = "udev";
    version = "0.3.0";
    src = pkgs.fetchFromGitHub {
      owner = "tree-sitter-grammars";
      repo = "tree-sitter-udev";
      rev = "2fcb563a4d56a6b8e8c129252325fc6335e4acbf";
      hash = "sha256-EZwYyhMOPlQoeIRCbHOIfMaO5WEK6eKIVeC1NQgm+is=";
    };
  };

  parserSource = builtins.path {
    path = ./udev_parser.py;
    name = "udev_parser.py";
  };
  parserDirectory = pkgs.linkFarm "udev-parser-pythonpath" [
    {
      name = "udev_parser.py";
      path = parserSource;
    }
  ];
  parserPython = pkgs.python3.withPackages (_: [ pkgs.python3Packages.tree-sitter ]);

  mkMdevHelper =
    {
      name,
      source,
      collect,
      group,
      match,
      setup ? "",
      caseExpression,
    }:
    let
      indentedCollector = lib.concatMapStringsSep "\n" (line: "    ${line}") (
        lib.splitString "\n" (lib.removeSuffix "\n" collect)
      );
      helperProgram = pkgs.writeText "${name}.py" ''
from __future__ import annotations

import sys
from pathlib import Path

from udev_parser import Clause, parse_rules


def collect_devices(rules: list[list[Clause]]) -> set[str]:
    devices: set[str] = set()
${indentedCollector}
    return devices


def main() -> None:
    source, output, grammar = sys.argv[1:]
    devices = collect_devices(parse_rules(Path(source), Path(grammar)))
    case_expression = ${builtins.toJSON caseExpression}
    with open(output, "w", encoding="utf-8") as script:
        script.write("#!/bin/sh\n")
        script.write(${builtins.toJSON setup})
        script.write(f"case {case_expression} in\n")
        for device in sorted(devices):
            script.write(f"  {device})\n")
            script.write('    ${pkgs.coreutils}/bin/chgrp ${group} /dev/"$MDEV"\n')
            script.write('    ${pkgs.coreutils}/bin/chmod 0660 /dev/"$MDEV"\n')
            script.write("    ;;\n")
        script.write("esac\n")


if __name__ == "__main__":
    main()
'';
      helper = pkgs.runCommand name { } ''
      export PYTHONPATH=${lib.escapeShellArg parserDirectory}
      ${parserPython}/bin/python ${helperProgram} ${source} "$out" ${udevGrammar}/parser
      ${pkgs.coreutils}/bin/chmod 0755 "$out"
      '';
    in
    "-${match} root:root 0600 @${helper}";
in
{
  _module.args = { inherit mkMdevHelper; };

  imports = [
    ./android.nix
    ./yubikey.nix
  ];
}
