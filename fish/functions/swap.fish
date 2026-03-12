function swap -d "Swap two files (wrapper for fileutil)"
    if test (count $argv) -ne 2
        echo "Usage: swap FILE1 FILE2"
        return 1
    end
    fileutil swap $argv[1] $argv[2]
end
