function utils -d "Miscellaneous utility functions"
    if test (count $argv) -lt 1
        echo "Usage: utils OPERATION [args...]"
        echo "Operations:"
        echo "  words              - Generate random word list"
        echo "  pony               - Show pony with fortune"
        echo "  guid [COUNT]       - Generate GUIDs (default: 1)"
        echo "  history PATTERN    - Search command history"
        echo "  json FILE          - Pretty-print JSON"
        echo "  tail FILE [LINES]  - Cut last N lines (default: 20)"
        echo "Example: utils guid 5"
        return 1
    end

    set -l operation $argv[1]

    switch $operation
        case words wordlist
            echo "Generating random word list..."
            fortune -l -n 145 | string upper | string split " " | \
                string replace -r '\W' '' | grep -E '.{5}' | sort -u | shuf

        case pony ponies
            echo "PONIES!!!"
            fortune | ponythink -b unicode

        case guid guidmaker
            set -l count 1
            if test (count $argv) -ge 2
                set count $argv[2]
            end
            echo "Generating $count GUID(s)..."
            for i in (seq 1 $count)
                uuidgen -r | string upper
            end

        case history hs
            if test (count $argv) -lt 2
                echo "Error: history requires a search pattern"
                return 1
            end
            history | grep $argv[2]

        case json purtyjson
            if test (count $argv) -lt 2
                echo "Error: json requires a filename"
                return 1
            end
            if not test -f $argv[2]
                echo "Error: File '$argv[2]' does not exist"
                return 1
            end
            python -m json.tool $argv[2]

        case tail cuttail
            if test (count $argv) -lt 2
                echo "Error: tail requires a filename"
                return 1
            end
            set -l lines 20
            if test (count $argv) -ge 3
                set lines $argv[3]
            end
            sed -n -e :a -e "1,$lines!{P;N;D;};N;ba" $argv[2]

        case '*'
            echo "Error: Unknown operation '$operation'"
            return 1
    end
end
# Massive wrapper collection for backward compatibility
