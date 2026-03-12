function favico -d "Create favicon (wrapper for imgproc)"
    if test (count $argv) -ne 1
        echo "Usage: favico INPUT_IMAGE"
        return 1
    end
    imgproc favicon $argv[1]
end
