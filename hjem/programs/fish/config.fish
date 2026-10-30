fish_add_path --global --path --append /run/wrappers/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin
set -e fish_history
set -gx GPG_TTY (tty)

if not set -q SSH_AUTH_SOCK
	set -l agent_sock /tmp/ssh-agent-(id -u).sock
	if test -S $agent_sock
		set -gx SSH_AUTH_SOCK $agent_sock
	else
		eval (@(lib.getExe' pkgs.openssh "ssh-agent")@ -c -a $agent_sock) > /dev/null
	end
end
