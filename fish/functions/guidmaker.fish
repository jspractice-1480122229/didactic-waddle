function guidmaker -d "Generate GUIDs (wrapper for utils)"
    if test (count $argv) -eq 0
        utils guid 1
    else
        utils guid $argv[1]
    end
end
