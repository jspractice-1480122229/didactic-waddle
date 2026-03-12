function louder -d "Make MP3 files louder with Lame"
    if test (count $argv) -ne 1
        echo "Usage: louder FILE.mp3"
        echo "Example: louder mysong.mp3"
        echo "Warning: This modifies the original file!"
        return 1
    end
    
    # Use lame's ability to overwrite in place
    lame --scale 2 --mp3input $argv[1] $argv[1]
end
