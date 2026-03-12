function tellme -d "Search or show details (wrapper for sysmgmt)"
    if test (count $argv) -lt 1
        echo "Error: tellme requires arguments"
        return 1
    end

    # MODE: details
    if test "$argv[1]" = "details"
    echo "DEBUG: argv = $argv"
        if test (count $argv) -lt 2
            echo "Error: details requires a package name"
            return 1
        end

        set query $argv[2]
        set mode normal

        # optional modes: --all, --repo <name>, --exact
        if test "$argv[2]" = "--all"
            set mode all
            set query $argv[3]
        else if test "$argv[2]" = "--repo"
            set mode repo
            set target_repo $argv[3]
            set query $argv[4]
        else if test "$argv[2]" = "--exact"
            set mode exact
            set query $argv[3]
        end

        # fuzzy search
        set raw (pacman -Ss "$query")

        # extract repo/pkg
        set matches (echo $raw \
            | string match -r '^[^/]+/[^ ]+' \
            | string trim)

        if test (count $matches) -eq 0
            echo "No packages found matching '$query'"
            return 1
        end

        # mode: repo filter
        if test "$mode" = "repo"
            set filtered (for m in $matches
                if string match -q "$target_repo/*" "$m"
                    echo $m
                end
            end)
            set matches $filtered
        end

        # mode: exact filter
        if test "$mode" = "exact"
            set filtered (for m in $matches
                set pkg (string replace -r '^[^/]+/' '' "$m")
                if test "$pkg" = "$query"
                    echo $m
                end
            end)
            set matches $filtered
        end

        if test (count $matches) -eq 0
            echo "No packages match criteria"
            return 1
        end

# verify matches (repo-aware)
set verified
for m in $matches
    set pkg (string replace -r '^[^/]+/' '' "$m")
    if pacman -Si "$pkg" >/dev/null 2>&1
        set verified $verified $m
    end
end


echo "DEBUG verified (after verify) = $verified"

        if test (count $verified) -eq 0
            echo "No valid packages found after verification"
            return 1
        end

        # mode: all → show all details
        if test "$mode" = "all"
            for m in $verified
                set pkg (string replace -r '^[^/]+/' '' "$m")
                pacman -Si "$pkg"
            end
            return
        end

        # auto-select
        if test (count $verified) -eq 1
            set selected $verified[1]
            set pkg (string replace -r '^[^/]+/' '' "$selected")
            pacman -Si "$pkg"
            return
        end

        # more than 4 → chunk or all
        set count (count $verified)
        if test $count -gt 4
            echo "More than four matches found."
            echo -n "Show [C]hunked or [A]ll? "
            read mode2

            if string match -q "A" "$mode2"
                # show all
                set i 1
                for m in $verified
                    echo "$i) $m"
                    set i (math $i + 1)
                end
                echo -n "Choose (1-"(math $count)", [N]one): "
                read choice

                switch $choice
                    case N n
                        return 1
                    case '*'
                        if string match -qr '^[0-9]+$' -- $choice
                            if test $choice -ge 1 -a $choice -le $count
                                set selected $verified[$choice]
                                set pkg (string replace -r '^[^/]+/' '' "$selected")
                                pacman -Si "$pkg"
                                return
                            end
                        end
                        echo "Invalid selection."
                        return 1
                end
            end

            # chunked mode
            set start 1
            set chunk_size 4

            while true
                set end (math $start + $chunk_size - 1)
                if test $end -gt $count
                    set end $count
                end

                echo "Matches $start to $end:"
                set i $start
                while test $i -le $end
                    echo (math $i - $start + 1)")" $verified[$i]
                    set i (math $i + 1)
                end

                echo -n "Choose (1-"(math $end - $start + 1)", [T]ry more, [N]one): "
                read choice

                switch $choice
                    case N n
                        return 1
                    case T t
                        set start (math $end + 1)
                        if test $start -gt $count
                            echo "No more chunks."
                            return 1
                        end
                    case '*'
                        if string match -qr '^[0-9]+$' -- $choice
                            set idx (math $start + $choice - 1)
                            if test $idx -ge $start -a $idx -le $end
                                set selected $verified[$idx]
                                set pkg (string replace -r '^[^/]+/' '' "$selected")
                                pacman -Si "$pkg"
                                return
                            end
                        end
                        echo "Invalid selection."
                end
            end
        end

        # 2–4 matches → simple numbered list
        echo "Multiple valid packages match '$query':"
        set i 1
        for m in $verified
            echo "$i) $m"
            set i (math $i + 1)
        end

        echo -n "Choose (1-"(math $count)", [N]one): "
        read choice

        switch $choice
            case N n
                return 1
            case '*'
                if string match -qr '^[0-9]+$' -- $choice
                    if test $choice -ge 1 -a $choice -le $count
                        set selected $verified[$choice]
                        set pkg (string replace -r '^[^/]+/' '' "$selected")
                        pacman -Si "$pkg"
                        return
                    end
                end
                echo "Invalid selection."
                return 1
        end
    end

    # default: search
    sysmgmt search $argv
end
