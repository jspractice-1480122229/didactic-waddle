function epoch -d "Convert unix timestamp (wrapper for fileutil)"
    if test (count $argv) -ne 1
        echo "Usage: epoch TIMESTAMP"
        return 1
    end
    fileutil epoch $argv[1]
end
