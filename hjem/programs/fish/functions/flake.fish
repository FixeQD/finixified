set -l nh_actions build test switch boot repl
set -l actions $nh_actions check search update

if test (count $argv) -eq 0
  printf 'Usage: flake <%s> [args]\n' (string join '|' $actions) >&2
  printf 'Examples:\n' >&2
  printf '  flake switch\n' >&2
  printf '  flake check --all-systems\n' >&2
  printf '  flake search [input-name] <term>\n' >&2
  return 2
end

set -l action $argv[1]
set -l args $argv[2..-1]

if not contains -- $action $actions
  printf 'Unknown action: %s\n' "$action" >&2
  printf 'Usage: flake <%s> [args]\n' (string join '|' $actions) >&2
  return 2
end

if contains -- $action $nh_actions
  @util.flake_cmd@ $action $args
  exit $status
end

switch $action
  case check
    if test (count $args) -eq 0
      printf 'Usage: flake check [options passed to nix flake check]\n' >&2
      printf 'Example: flake check --all-systems\n' >&2
      return 2
    end
    command nix flake check "$NIX_FLAKE" $args
  case search
    @util.flake_search@ $args
  case update
    command nix flake update "$NIX_FLAKE"
    or return 1
    printf 'Flake inputs updated (including the nix-index database).\n' >&2
    printf 'Rebuild to activate:\n  flake switch\n' >&2
end
