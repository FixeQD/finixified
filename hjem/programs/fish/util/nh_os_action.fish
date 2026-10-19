function @util.nh_os_action@
  set -l words (commandline -opc)

  if test (count $words) -ge 3; and test "$words[1]" = nh; and test "$words[2]" = os
    contains -- "$words[3]" switch boot test build repl
    return $status
  end

  return 1
end
