function bestytclip -d "Download best video from YouTube (wrapper for ytdl)"
    ytdl video $argv
end
# 3digit.fish
function 3digit -d "Generate 3-digit random number (wrapper for randumb)"
    randumb 3
end
# 5digit.fish
function 5digit -d "Generate 5-digit random number (wrapper for randumb)"
    randumb 5
end
# Keep both dummyfile functions as wrappers for compatibility
