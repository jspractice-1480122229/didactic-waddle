# Function for copying directories recursively with verbose output.
function cpdir
    cp -frv $argv[1] $argv[2]
end