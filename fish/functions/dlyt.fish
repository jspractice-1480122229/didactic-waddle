function dlyt -d "YouTube download with multiple modes"
    if test (count $argv) -lt 2
        echo "Usage: dlyt MODE URL [URL2 URL3...]"
        echo "Modes:"
        echo "  rip    - Best audio with metadata (m4a)"
        echo "  audio  - Best audio only"
        echo "  video  - Best video quality"
        echo "Example: dlyt rip https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        return 1
    end

    set -l mode $argv[1]
    set -l urls $argv[2..-1]

    switch $mode
        case rip
            yt-dlp -f bestaudio --extract-audio --prefer-ffmpeg \
                --audio-format m4a --embed-thumbnail --add-metadata \
                --parse-metadata "comment:%(webpage_url)s" \
                -o '%(title)s.%(ext)s' $urls
        case audio
            yt-dlp -f bestaudio $urls
        case video
            yt-dlp -f best $urls
        case '*'
            echo "Error: Unknown mode '$mode'"
            echo "Valid modes: rip, audio, video"
            return 1
    end
end
