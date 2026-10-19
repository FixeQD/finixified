# Terminal title
set -l command
if set -q argv[1]
    set command $argv[1]
else
    set command (status current-command)
    if test "$command" = fish
        set command
    end
end

if test -z "$command"
    set -l buffer (commandline --current-buffer 2>/dev/null | string collect | string trim)
    if test -n "$buffer"
        set command $buffer
    end
end

set -l ssh
if set -q SSH_TTY
    set ssh (prompt_hostname | string sub -l 10 | string collect)
end

set -l location (prompt_pwd -d 1 -D 1)

set -l parts
test -n "$ssh"
and set parts $parts $ssh

if test -n "$command"
    set parts $parts (string shorten -m 24 -- "$command" | string collect)
end

if set -q fish_pid
    set parts $parts "#$fish_pid"
end

test -n "$location"
and set parts $parts $location

echo -- (string join ' | ' -- $parts)
