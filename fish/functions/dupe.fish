function dupe -d "Duplicate files (wrapper for fileutil)"
    if test (count $argv) -ne 2
        echo "Usage: dupe FILE COUNT"
        return 1
    end
    fileutil dupe $argv[1] $argv[2]
end
