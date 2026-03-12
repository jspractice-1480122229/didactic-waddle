function pfimpf -d "Extract archive (wrapper for archive)"
    if test (count $argv) -ne 1
        echo "Usage: pfimpf ARCHIVE_FILE"
        return 1
    end
    archive extract $argv[1]
end
