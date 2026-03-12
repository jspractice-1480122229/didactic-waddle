function pod -d "Podman container operations" -a operation
    switch $operation
        case ls
            podman ps -a
        case stop
            podman stop $(podman ps -q)
        case rm
            # Same as your nyope function
            podman container rm $(podman ps -aq)
        case prune
            podman system prune -af
        case stats
            podman stats
        case logs
            if test (count $argv) -gt 1
                podman logs -f $argv[2]
            else
                echo "Usage: pod logs CONTAINER_NAME"
            end
        case '*'
            echo "Usage: pod [ls|stop|rm|prune|stats|logs] [args]"
    end
end