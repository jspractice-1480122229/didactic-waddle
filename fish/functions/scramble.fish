function scramble -d "Encrypt file (wrapper for crypt)"
    if test (count $argv) -ne 2
        echo "Usage: scramble INPUT OUTPUT"
        return 1
    end
    crypt encrypt $argv[1] $argv[2]
end
