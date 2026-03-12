function descramble -d "Decrypt file (wrapper for crypt)"
    if test (count $argv) -ne 2
        echo "Usage: descramble INPUT OUTPUT"
        return 1
    end
    crypt decrypt $argv[1] $argv[2]
end
