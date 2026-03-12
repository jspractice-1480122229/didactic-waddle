function fileutil -d "File utility operations"
    if test (count $argv) -lt 1
        echo "Usage: fileutil OPERATION [args...]"
        echo "Operations:"
        echo "  lowercase FILE [FILE2...] - Convert filenames to lowercase"
        echo "  swap FILE1 FILE2          - Swap two files"
        echo "  dupe FILE COUNT           - Make COUNT copies of FILE"
        echo "  epoch TIMESTAMP           - Convert unix timestamp to date"
        echo "Example: fileutil lowercase *.JPG"
        return 1
    end

    set -l operation $argv[1]

    switch $operation
        case lowercase
            if test (count $argv) -lt 2
                echo "Error: lowercase requires at least one filename"
                return 1
            end
            
            for file in $argv[2..-1]
                if not test -e $file
                    echo "Warning: '$file' does not exist, skipping"
                    continue
                end
                
                set -l new (string lower $file)
                if test $file != $new
                    mv $file $new
                    echo "Renamed: $file -> $new"
                else
                    echo "No change: $file"
                end
            end
            
        case swap
            if test (count $argv) -ne 3
                echo "Error: swap requires exactly 2 filenames"
                return 1
            end
            
            set -l file1 $argv[2]
            set -l file2 $argv[3]
            
            if not test -e $file1
                echo "Error: '$file1' does not exist"
                return 1
            end
            if not test -e $file2
                echo "Error: '$file2' does not exist"
                return 1
            end
            
            set -l tmp tmp.$fish_pid
            mv $file1 $tmp
            mv $file2 $file1
            mv $tmp $file2
            echo "Swapped: $file1 <-> $file2"
            
        case dupe
            if test (count $argv) -ne 3
                echo "Error: dupe requires FILE and COUNT"
                return 1
            end
            
            set -l file $argv[2]
            set -l count $argv[3]
            
            if not test -f $file
                echo "Error: '$file' does not exist"
                return 1
            end
            
            for i in (seq 1 $count)
                cp $file $i$file
                echo "Created: $i$file"
            end
            
        case epoch
            if test (count $argv) -ne 2
                echo "Error: epoch requires a timestamp"
                return 1
            end
            date --date=@$argv[2]
            
        case '*'
            echo "Error: Unknown operation '$operation'"
            return 1
    end
end
# Backward compatibility wrappers
