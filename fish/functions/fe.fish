function fe -d "Find and execute (wrapper for finder)"
    if test (count $argv) -lt 2
        echo "Usage: fe PATTERN COMMAND [ARGS...]"
        return 1
    end
    finder exec $argv
end
