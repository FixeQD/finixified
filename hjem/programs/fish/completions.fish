complete -c nh -n @util.nh_os_action@ -s H -a "@hostList@" -d "Finix host"
complete -c nh -n @util.nh_os_action@ -l hostname -a "@hostList@" -d "Finix host"

complete -c flake -f -n "__fish_seen_subcommand_from build test switch boot repl check search update" -d "Finix action"
complete -c flake -f -n "__fish_seen_subcommand_from build test switch boot repl" -a "@hostList@" -d "Finix host"
complete -c flake -f -n "__fish_seen_subcommand_from check" -a "--all-systems --no-build --show-trace --impure" -d "nix flake check option"
complete -c flake -f -n "__fish_seen_subcommand_from search" -a "nixpkgs" -d "Search nixpkgs only"
