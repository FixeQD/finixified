# Reports finished/stopped/signal-killed jobs
set -l red (set_color -o red)
set -l yellow (set_color -o yellow)
set -l green (set_color -o green)
set -l normal (set_color normal)

set -l cmd_line (string shorten -m 32 -- $cmd_line | string collect)

set -l message

switch $signal_or_end_name
    case STOPPED
        set message "$yellow⏸ $cmd_line $normal(job $job_id stopped)"
    case ENDED
        set message "$green✔ $cmd_line $normal(job $job_id ended)"
    case 'SIG*'
        set -l detail
        if test -n "$proc_pid"
            set detail "pid $proc_pid ($proc_name)"
        end
        if test -n "$signal_desc"
            set detail (string join ', ' -- $detail $signal_desc | string collect)
        end
        if test -z "$detail"
            set detail "job $job_id"
        end
        set message "$red✖ $cmd_line $normal(killed by $signal_or_end_name, $detail)"
end

if test -z "$message"
    return 0
end

if test $is_foreground -eq 0; and test $signal_or_end_name != STOPPED
    __fish_echo string join \n -- $message
else
    string join >&2 \n -- $message
end
