function nthdigit --description 'Generating N digit number'
    set -l n_digit 3
    if test -n "$argv[1]"
        set n_digit $argv[1]
    end
    if not test "$n_digit" -gt 0 2>/dev/null
        echo "Error: Number of digits must be a positive integer"
        return 1
    end
    if test $n_digit -eq 1
        echo (random 0 9)
    else
        set -l result ""
        set -l i 1
        while test $i -le $n_digit
            set -l digit 0
            if test $i -eq 1
                set digit (random 1 9)
            else
                set digit (random 0 9)
            end
            set result "$result$digit"
            set i (math "$i + 1")
        end
        echo $result
    end
end
