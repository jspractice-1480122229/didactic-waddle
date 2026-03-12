function ff -d "Find files by name (wrapper for finder)"
    if test (count $argv) -ne 1
        echo "Usage: ff PATTERN"
        return 1
    end
    finder name $argv[1]
end
