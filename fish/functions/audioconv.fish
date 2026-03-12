function audioconv -d "Audio format conversion"
    if test (count $argv) -lt 1
        echo "Usage: audioconv OPERATION [args...]"
        echo "Operations:"
        echo "  mp3        - Convert WAV/OGG/FLAC to MP3"
        echo "  shrink     - Compress MP3s for podcasts"
        echo "  louder FILE - Make MP3 louder"
        echo "  play [DIR] - Play random audio files"
        echo "Example: audioconv mp3"
        return 1
    end

    set -l operation $argv[1]
    
    switch $operation
        case mp3
            # Convert various formats to MP3
            for file in *.{wav,ogg,flac}
                if not test -f $file
                    continue
                end
                set -l base (path change-extension '' $file)
                ffmpeg -i $file -vn -ar 44100 -ac 2 -b:a 192k $base.mp3
                echo "Converted $file -> $base.mp3"
            end
            
        case shrink
            set -l output_dir "compressed"
            mkdir -p $output_dir
            
            for file in *.mp3
                if not test -f $file
                    continue
                end
                ffmpeg -n -i $file -metadata genre="Podcast" -ac 1 -ab 40k \
                    -ar 22050 -id3v2_version 3 -write_id3v1 1 -vsync 2 \
                    $output_dir/$file
                echo "Compressed $file -> $output_dir/$file"
            end
            
        case play
            set -l dir "."
            if test (count $argv) -ge 2
                set dir $argv[2]
            end
            
            for file in (find $dir -type f \( -name "*.mp3" -o -name "*.flac" -o -name "*.wav" \) | shuf)
                echo "Playing: $file"
                ffplay -autoexit -nodisp $file >/dev/null 2>&1
            end
            
        case '*'
            echo "Error: Unknown operation '$operation'"
            return 1
    end
end
# Backward compatibility wrappers
