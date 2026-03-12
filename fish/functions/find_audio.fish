# ~/.config/fish/functions/find_audio.fish

# A function to find common audio files recursively within a specified directory.
# Arguments:
#   $argv[1] = The directory to start the search (e.g., /home/rex/Music)
#   $argv[2..-1] = Any additional 'find' arguments (e.g., -exec, -mtime, -delete)
function find_audio
    # If no directory is provided, default to the current directory ('.')
    if test (count $argv) -eq 0
        set search_dir "."
    else
        set search_dir $argv[1]
    end

    # Pass the remaining arguments directly to the find command
    set find_args $argv[2..-1]

    # The core 'find' command
    find "$search_dir" -type f \
        \( \
            -iname "*.mp3" -o -iname "*.flac" -o -iname "*.m4a" \
            -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.aac" \
            -o -iname "*.m4p" -o -iname "*.wma" -o -iname "*.opus" \
            -o -iname "*.ape" -o -iname "*.wv" -o -iname "*.dsf" \
            -o -iname "*.dff" -o -iname "*.alac" -o -iname "*.aiff" \
            -o -iname "*.au" -o -iname "*.amr" -o -iname "*.ac3" \
            -o -iname "*.dts" -o -iname "*.ra" -o -iname "*.mid" \
        \) $find_args
end

# Usage Example:
# find_audio /path/to/search -exec mpv {} +