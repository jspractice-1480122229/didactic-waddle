function dlyt -d "YouTube download with multiple modes"
    if test (count $argv) -lt 2
        echo "Usage: dlyt MODE URL [URL2 URL3...]"
        echo "Modes:"
        echo "  video  - Best quality video, muxed (single video or playlist)"
        echo "  audio  - Best quality audio, raw stream, no post-processing"
        echo "  rip    - Best audio, transcoded to m4a, with metadata/thumbnail"
        echo "  both   - Best video AND best audio in one download pass (no re-fetch)"
        echo "Example: dlyt both https://youtube.com/playlist?list=..."
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
            # bv*+ba merges the true best video-only + audio-only streams;
            # plain "-f best" caps out at YouTube's old pre-muxed formats
            # (often <=720p) since higher resolutions are video-only.
            yt-dlp -f "bv*+ba/b" --merge-output-format mkv \
                -o '%(title)s.%(ext)s' $urls
        case both
            # One download pass gets both outputs: merge bv*+ba into the
            # final video, then -x extracts audio from that same merged
            # file locally via ffmpeg (no second network fetch).
            # --audio-format best = remux/copy, no lossy re-encode.
            yt-dlp -f "bv*+ba/b" --merge-output-format mkv \
                -x --audio-format best -k \
                --embed-thumbnail --add-metadata \
                -o '%(title)s.%(ext)s' $urls
            # --keep-video also preserves the raw pre-merge video-only/
            # audio-only fragments (Title.f616.mp4, Title.f251.webm etc.)
            # alongside the final .mkv/.opus — clean those up.
            find . -maxdepth 1 -regextype posix-extended \
                -regex './.*\.f[0-9]+\.[A-Za-z0-9]+$' -delete
        case '*'
            echo "Error: Unknown mode '$mode'"
            echo "Valid modes: video, audio, rip, both"
            return 1
    end
end
