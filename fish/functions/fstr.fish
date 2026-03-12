function fstr -d "Find string in files (wrapper for finder)"
    if test (count $argv) -eq 0
        echo "Usage: fstr [-nc|--no-color] [--debug] [-i] PATTERN [FILE_PATTERN]"
        return 1
    end

    set -l no_color 0
    set -l debug 0
    set -l args $argv
    
    # Check for --nc or --no-color flag and remove from args
    if contains -- -nc $argv; or contains -- --no-color $argv
        set no_color 1
        set args (string match -v -- -nc $args)
        set args (string match -v -- --no-color $args)
    end
    
    # Check for --debug flag and remove from args
    if contains -- --debug $argv
        set debug 1
        set args (string match -v -- --debug $args)
    end

    # Check for case-insensitive flag
    if test (count $args) -ge 1; and test $args[1] = "-i"
        if test (count $args) -lt 2
            echo "Error: -i flag requires a pattern"
            return 1
        end
        
        set -l pattern $args[2]
        set -l file_pattern "*"
        
        # If file pattern provided, wrap it with wildcards
        if test (count $args) -ge 3
            set file_pattern "*$args[3]*"
        end
        
        if test $debug -eq 1
            echo "Calling finder content with arguments: -i $pattern $file_pattern"
        end
        
        # Build finder command with appropriate flags
        set -l finder_args content
        if test $debug -eq 0
            set -a finder_args --quiet
        end
        if test $no_color -eq 1
            set -a finder_args --no-color
        end
        set -a finder_args -i $pattern $file_pattern
        
        finder $finder_args
    else
        set -l pattern $args[1]
        set -l file_pattern "*"
        
        # If file pattern provided, wrap it with wildcards
        if test (count $args) -ge 2
            set file_pattern "*$args[2]*"
        end
        
        if test $debug -eq 1
            echo "Calling finder content with arguments: $pattern $file_pattern"
        end
        
        # Build finder command with appropriate flags
        set -l finder_args content
        if test $debug -eq 0
            set -a finder_args --quiet
        end
        if test $no_color -eq 1
            set -a finder_args --no-color
        end
        set -a finder_args $pattern $file_pattern
        
        finder $finder_args
    end
end
