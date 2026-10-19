# Searches packages in the flake inputs resolved from the lock file.
# Usage: __flake_search [input-name] <term>
set -l scope
set -l term

if test (count $argv) -gt 1
  set scope $argv[1]
  set term $argv[2]
else
  set term $argv[1]
end

if test -z "$term"
  printf 'Usage: flake search [input-name] <term>\n' >&2
  printf 'Example: flake search ripgrep\n' >&2
  return 2
end

if set -q scope[1]
  set scope_arg $scope
else
  set scope_arg ""
end

set -l inputs (
  command nix flake metadata --json "$NIX_FLAKE" \
    | @pkgs.jq@/bin/jq -r --arg scope "$scope_arg" '
        .locks.nodes as $nodes
        | $nodes.root.inputs
        | to_entries[]
        | .key as $name
        | $nodes[.value]
        | (.locked // {}) as $l
        | select($l.type == "github")
        | select($scope == "" or $name == $scope)
        | "\($name)\tgithub:\($l.owner)/\($l.repo)/\($l.rev)"
      '
)

if test (count $inputs) -eq 0
  if test -n "$scope"
    printf 'No such flake input: %s\n' "$scope" >&2
  else
    printf 'Could not read flake inputs from %s\n' "$NIX_FLAKE" >&2
  end
  return 1
end

set -l output_file (mktemp)

for entry in $inputs
  set -l name (string split \t -- $entry)[1]
  set -l ref (string split \t -- $entry)[2]

  command nix search "$ref#" "$term" >$output_file 2>/dev/null &

  @util.spinner@ $last_pid "Searching $name"

  wait $last_pid

  if test -s $output_file
    printf '\n%s (nixpkgs#%s):\n' (set_color -o blue)$name (set_color normal) >&2
    cat $output_file
  end
end

command rm -f $output_file
