# Function for changing permissions with verbose output.
function chmod
    chmod -c "$argv[1]" "$argv[2]"
end