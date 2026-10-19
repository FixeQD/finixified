set -l action $argv[1]
set -l args $argv[2..-1]
set -l host (command uname -n)

if test (count $args) -gt 0; and not string match -qr '^-' -- $args[1]
  if contains -- $args[1] @hostList@
    set host $args[1]
    set -e args[1]
  else
    printf 'Unknown Finix host: %s\n' "$args[1]" >&2
    printf 'Known hosts: @hostList@\n' >&2
    printf 'Usage: flake %s [@hostList@] [nh options]\n' "$action" >&2
    return 2
  end
end

switch $host
  case @hostList@
  case '*'
    printf 'Unknown Finix host: %s\n' "$host" >&2
    printf 'Known hosts: @hostList@\n' >&2
    printf 'Usage: flake %s [@hostList@] [nh options]\n' "$action" >&2
    return 2
end

command nh os $action --hostname $host $args
