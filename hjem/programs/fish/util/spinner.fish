set -l frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
set -l frame_count (count $frames)
set -l tick 0

function __spinner_erase --on-signal INT --on-signal TERM --on-signal HUP
  printf '\r\033[2K'
  functions --erase __spinner_erase
end

# Spins until the process given as $argv[1] exits, or until interrupted.
while kill -0 $argv[1] 2>/dev/null
  printf '\r\033[2K%s %s' $frames[$frame_count] "$argv[2]"

  set tick (math "$tick + 1")
  set frame_index (math "$tick % $frame_count + 1")
  set frames $frames[2..-1] $frames[1]

  sleep 0.1
end

printf '\r\033[2K'
