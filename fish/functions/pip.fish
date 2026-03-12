function pip
    if test (count $argv) -eq 1; and test "$argv[1]" = "--version"
        uv --version
        return
    end

    echo "pip is deprecated here; using uv pip instead" >&2
    uv pip $argv
end
