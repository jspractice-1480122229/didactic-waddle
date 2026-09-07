# ssh-agent bootstrap for non-systemd init systems (e.g. antiX/sysvinit, runit).
# Sourced from ~/.bash_profile by bootstrap.sh's ssh_agent module when no
# systemd user session is available (systemd hosts use the real
# systemd/user/ssh-agent.service + ssh-add.service units instead).
#
# Reuses whatever agent is already reachable (started by the desktop
# session, a prior login, etc.) before starting a new one, and caches a
# freshly-started agent's env so subsequent shells reuse it too.

ssh_agent_alive() {
    [ -n "$SSH_AUTH_SOCK" ] || return 1
    ssh-add -l >/dev/null 2>&1
    [ $? -ne 2 ]
}

ssh_agent_ensure() {
    ssh_agent_alive && return 0

    cache="$HOME/.ssh/agent-env"
    if [ -f "$cache" ]; then
        . "$cache" >/dev/null 2>&1
        ssh_agent_alive && return 0
    fi

    ssh-agent -s > "$cache"
    . "$cache" >/dev/null
    ssh-add "$HOME/.ssh/id_ed25519" >/dev/null 2>&1
}

ssh_agent_ensure
