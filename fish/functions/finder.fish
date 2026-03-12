function finder -d "Enhanced search functions"
    if test (count $argv) -lt 1
        echo "Usage: finder OPERATION [args...]"
        echo "Operations:"
        echo "  name PATTERN              - Find files by name"
        echo "  exec PATTERN COMMAND      - Find files and execute command"
        echo "  content [--quiet] [--no-color] [-i] PATTERN [EXT] - Find by content"
        echo "Example: finder name '*.mp3'"
        echo "Example: finder content -i 'TODO' '*.txt'"
        return 1
    end

    set -l operation $argv[1]

    switch $operation
        case name
            if test (count $argv) -lt 2
                echo "Error: name requires a pattern"
                return 1
            end
            find . -type f -iname "*$argv[2]*" -ls
            
        case exec
            if test (count $argv) -lt 3
                echo "Error: exec requires pattern and command"
                return 1
            end
            find . -type f -iname "*$argv[2]*" -exec $argv[3..-1] {} \;
            
        case content
            set -l quiet 0
            set -l no_color 0
            set -l args $argv[2..-1]
            
            # Check for --quiet flag and remove from args
            if contains -- --quiet $args
                set quiet 1
                set args (string match -v -- --quiet $args)
            end
            
            # Check for --no-color flag and remove from args
            if contains -- --no-color $args
                set no_color 1
                set args (string match -v -- --no-color $args)
            end
            
            # Set grep color flag
            set -l color_flag "--color=always"
            if test $no_color -eq 1
                set color_flag "--color=never"
            end
            
            # Check for case-insensitive flag
            if test (count $args) -ge 1; and test $args[1] = "-i"
                if test (count $args) -lt 2
                    echo "Error: content requires a search pattern"
                    return 1
                end
                
                set -l pattern $args[2]
                set -l ext_pattern "*"
                
                # Check for file extension pattern
                if test (count $args) -gt 2
                    set ext_pattern $args[3]
                end
                
                if test $quiet -eq 0
                    echo "Calling grep with arguments: $color_flag -sn -i $pattern"
                end
                find . -type f -iname $ext_pattern -print0 | \
                    xargs -0 grep $color_flag -sn -i $pattern 2>/dev/null | more
            else
                if test (count $args) -lt 1
                    echo "Error: content requires a search pattern"
                    return 1
                end
                
                set -l pattern $args[1]
                set -l ext_pattern "*"
                
                # Check for file extension pattern
                if test (count $args) -gt 1
                    set ext_pattern $args[2]
                end
                
                if test $quiet -eq 0
                    echo "Calling grep with arguments: $color_flag -sn $pattern"
                end
                find . -type f -iname $ext_pattern -print0 | \
                    xargs -0 grep $color_flag -sn $pattern 2>/dev/null | more
            end
                
        case '*'
            echo "Error: Unknown operation '$operation'"
            return 1
    end
end
# Backward compatibility wrappers
