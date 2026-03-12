function maxwidthvar -d "Resize images to max width (wrapper for imgproc)"
    if test (count $argv) -ne 1
        echo "Usage: maxwidthvar WIDTH"
        return 1
    end
    imgproc resize $argv[1]
end
