function randumb -d "Generate random numbers with specified digit count"
    if test (count $argv) -ne 1
        echo "Usage: randumb DIGITS"
        echo "Example: randumb 3  # generates 100-999"
        echo "Example: randumb 5  # generates 10000-99999"
        return 1
    end

    set -l digits $argv[1]
    
    switch $digits
        case 3
            random 100 999
        case 5
            random 10000 99999
        case '*'
            # Generic case for any digit count
            set -l min (math "10^($digits-1)")
            set -l max (math "10^$digits - 1")
            random $min $max
    end
end
