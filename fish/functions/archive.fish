function archive -d "Archive operations"
    if test (count $argv) -lt 1
        echo "Usage: archive OPERATION [args...]"
        echo "Operations:"
        echo "  extract FILE    - Extract any supported archive"
        echo "  encrypt IN OUT  - Encrypt with DES3"
        echo "  decrypt IN OUT  - Decrypt with DES3"
        echo "Supported formats: tar.bz2, tar.gz, bz2, rar, gz, tar, tbz2, tgz, zip, Z, 7z, xz"
        echo "Example: archive extract myfile.tar.gz"
        return 1
    end

    set -l operation $argv[1]

    switch $operation
        case extract
            if test (count $argv) -ne 2
                echo "Error: extract requires a filename"
                return 1
            end
            
            set -l file $argv[2]
            if not test -f $file
                echo "Error: File '$file' does not exist"
                return 1
            end

            echo "Extracting $file..."
            switch (string lower (path extension $file))
                case .bz2
                    if string match -q "*.tar.bz2" $file; or string match -q "*.tbz2" $file
                        tar xvjf $file
                    else
                        bunzip2 $file
                    end
                case .gz
                    if string match -q "*.tar.gz" $file; or string match -q "*.tgz" $file
                        tar xvzf $file
                    else
                        gunzip $file
                    end
                case .rar
                    if command -v unrar >/dev/null
                        unrar x $file
                    else
                        echo "Error: unrar not installed"
                        return 1
                    end
                case .zip
                    unzip $file
                case .Z
                    uncompress $file
                case .tar
                    tar xvf $file
                case .xz
                    unxz $file
                case .7z
                    7z x $file
                case '*'
                    echo "Error: Unsupported format for '$file'"
                    return 1
            end
            
        case encrypt
            if test (count $argv) -ne 3
                echo "Error: encrypt requires INPUT and OUTPUT files"
                return 1
            end
            crypt encrypt $argv[2] $argv[3]
            
        case decrypt
            if test (count $argv) -ne 3
                echo "Error: decrypt requires INPUT and OUTPUT files"
                return 1
            end
            crypt decrypt $argv[2] $argv[3]
            
        case '*'
            echo "Error: Unknown operation '$operation'"
            return 1
    end
end
