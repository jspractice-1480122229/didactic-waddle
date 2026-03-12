function noblanks -d "Remove spaces and blank lines from file"
    if test (count $argv) -ne 1
        echo "Usage: noblanks FILENAME"
        echo "Example: noblanks messy_file.txt"
        echo "Warning: This modifies the original file!"
        return 1
    end
    
    # Create backup and process in one go
    cp $argv[1] $argv[1].bak
    perl -nlwe 'tr/ //d; print if length' $argv[1].bak > $argv[1]
    rm $argv[1].bak
end
# Keep these separate wrapper functions for backward compatibility
