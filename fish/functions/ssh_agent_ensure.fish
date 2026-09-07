function ssh_agent_ensure -d "Reuse or start a persistent SSH agent (non-systemd init fallback)"
    if set -q SSH_AUTH_SOCK
        ssh-add -l >/dev/null 2>&1
        if test $status -ne 2
            return 0
        end
    end

    set -l cache "$HOME/.ssh/agent-env.fish"
    if test -f "$cache"
        source "$cache"
        if set -q SSH_AUTH_SOCK
            ssh-add -l >/dev/null 2>&1
            if test $status -ne 2
                return 0
            end
        end
    end

    ssh-agent -c | string replace -r '^setenv (\S+) (.*);$' 'set -gx $1 $2;' > "$cache"
    source "$cache"
    ssh-add "$HOME/.ssh/id_ed25519" >/dev/null 2>&1
end
