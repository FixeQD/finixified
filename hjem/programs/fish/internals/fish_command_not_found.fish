if test (count $argv) -eq 0
  __fish_default_command_not_found_handler $argv
  return 127
end

set -l command_name $argv[1]

if not type -q nix-locate
  __fish_default_command_not_found_handler $argv
  return 127
end

printf "fish: Unknown command: %s\n" "$command_name" >&2

set -l results_file (mktemp)

command nix-locate \
  --minimal \
  --type x \
  --at-root \
  --whole-name "/bin/$command_name" >$results_file 2>/dev/null &

set -l lookup_pid $last_pid

@util.spinner@ $lookup_pid "Searching nix-index for '$command_name'"

wait $lookup_pid

set -l results (
  string replace -r '\.out$' '' <$results_file \
    | string match -v '^\$' \
    | sort -u
)

set -l exact (string match -- "$command_name" $results)
set -l others (string match -v -- "$command_name" $results)
set results $exact $others

command rm -f $results_file

set -l extra_args ""
if test (count $argv) -gt 1
  set extra_args (string join ' ' -- $argv[2..-1])
end

if test (count $results) -gt 0
  printf "Nix packages providing %s:\n" "$command_name" >&2
  for package in $results[1..5]
    if test "$package" = "$command_name"
      if test -n "$extra_args"
        printf "  nix run nixpkgs#%s -- %s\n" "$package" "$extra_args" >&2
      else
        printf "  nix run nixpkgs#%s\n" "$package" >&2
      end
    else if test -n "$extra_args"
      printf "  nix shell nixpkgs#%s -c %s %s\n" "$package" "$command_name" "$extra_args" >&2
    else
      printf "  nix shell nixpkgs#%s -c %s\n" "$package" "$command_name" >&2
    end
  end
else
  printf "No Nix package found providing %s.\n" "$command_name" >&2
end

return 127
