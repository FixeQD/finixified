# Template engine for the fish config
{ inputs, lib, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  hosts = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../../hosts);
  hostNames = lib.attrNames hosts;

  evalSnippet =
    code:
    (import (builtins.toFile "fish-snippet.nix" "scope:\nlet\n  inherit (scope) inputs lib pkgs system hostNames util;\n  hostList = lib.concatStringsSep \" \" hostNames;\nin\n${code}\n") {
      inherit inputs lib pkgs system hostNames util;
    });

  fillFile =
    path:
    let
      parts = lib.splitString "@" (builtins.readFile path);
    in
    lib.concatStringsSep "" (
      lib.imap0 (
        i: part:
        if builtins.div i 2 * 2 == i then part else toString (evalSnippet (lib.trim part))
      ) parts
    );

  # util/*.fish are internal helpers, exposed to templates as @util.<name>@ and
  # installed as __<name> so they never shadow a user-facing command.
  util = lib.foldl' (
    acc: name:
    acc // { "${lib.removeSuffix ".fish" name}" = "__${lib.removeSuffix ".fish" name}"; }
  ) { } (lib.filter (name: lib.hasSuffix ".fish" name) (lib.attrNames (builtins.readDir ./util)));

  # Recursively collects every *.fish template, keyed by its path relative to this dir.
  collect =
    dir: prefix:
    lib.concatMapAttrs (
      name: entry:
      let
        relPath = "${prefix}${name}";
      in
      if entry == "directory" then collect "${dir}/${name}" "${relPath}/"
      else if lib.hasSuffix ".fish" name then {
        ${lib.removeSuffix ".fish" relPath} = fillFile "${dir}/${name}";
      }
      else { }
    ) (builtins.readDir dir);

  templates = collect (toString ./. + "/.") "";

  # functions/* are user-facing, internals/* override fish's own hooks, util/* get a __ prefix.
  toFunction = name: value:
    if lib.hasPrefix "util/" name then {
      "${util.${lib.removePrefix "util/" name}}" = value;
    }
    else if lib.hasPrefix "functions/" name then {
      "${lib.removePrefix "functions/" name}" = value;
    }
    else if lib.hasPrefix "internals/" name then {
      "${lib.removePrefix "internals/" name}" = value;
    }
    else { };

  isFunction = name: lib.hasPrefix "functions/" name
    || lib.hasPrefix "internals/" name
    || lib.hasPrefix "util/" name;

  functions = lib.foldl' (acc: name: acc // toFunction name templates.${name}) { }
    (lib.attrNames templates);

  topLevel = lib.filterAttrs (name: _: !(isFunction name)) templates;
in
{
  inherit templates functions;

  configFile = topLevel."config";
  confFiles = lib.removeAttrs topLevel [ "config" ];
}
