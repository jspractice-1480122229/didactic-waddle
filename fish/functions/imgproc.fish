function imgproc -d "Image processing operations"
    if test (count $argv) -lt 1
        echo "Usage: imgproc OPERATION [args...]"
        echo "Operations:"
        echo "  resize WIDTH [QUALITY] - Resize images to max width, convert to WebP"
        echo "  clearmeta              - Strip metadata from JPEGs"
        echo "  tiny [SIZE]            - Create tiny thumbnails (default 48x38)"
        echo "  thumbs [SIZE]          - Create larger thumbnails (default 150x100)"
        echo "  favicon INPUT [OUTPUT] - Create 16x16 favicon"
        echo "Example: imgproc resize 800 60"
        return 1
    end

    set -l operation $argv[1]
    
    switch $operation
        case resize
            if test (count $argv) -lt 2
                echo "Error: resize requires WIDTH argument"
                return 1
            end
            set -l width $argv[2]
            set -l quality 60
            if test (count $argv) -ge 3
                set quality $argv[3]
            end
            
            for file in *.{jpg,jpeg,png,gif,bmp}
                if not test -f $file
                    continue
                end
                
                set -l ogwidth (identify -format "%w" $file)
                if test $ogwidth -ge $width
                    set -l base (path change-extension '' $file)
                    set -l ext (path extension $file)
                    
                    magick $file -resize {$width}x\> -quality $quality tmp.$fish_pid$ext
                    set -l nuheight (identify -format "%h" tmp.$fish_pid$ext)
                    cwebp -q $quality -m 6 -mt tmp.$fish_pid$ext -o kf_{$base}_{$width}x{$nuheight}.webp
                    rm tmp.$fish_pid$ext
                    echo "Processed $file -> kf_{$base}_{$width}x{$nuheight}.webp"
                end
            end
            
        case clearmeta
            for file in *.jpg
                jpegoptim -pqt --strip-all $file
            end
            
        case tiny
            set -l size "48x38"
            if test (count $argv) -ge 2
                set size $argv[2]
            end
            
            for file in *.jpg
                if not test -f $file
                    continue
                end
                set -l width (identify -format "%w" $file)
                set -l height (identify -format "%h" $file)
                
                if test $width -ge 49; or test $height -ge 39
                    set -l base (path change-extension '' $file)
                    convert -scale $size $file TN_$base.jpg
                    jpegoptim -pqt --strip-all TN_$base.jpg
                    echo "Created TN_$base.jpg"
                end
            end
            
        case thumbs
            set -l size "150x100"
            if test (count $argv) -ge 2
                set size $argv[2]
            end
            
            for file in *.jpg
                if not test -f $file
                    continue
                end
                set -l width (identify -format "%w" $file)
                set -l height (identify -format "%h" $file)
                
                if test $width -ge 151; or test $height -ge 101
                    set -l base (path change-extension '' $file)
                    convert -sample $size $file {$base}_thumb.jpg
                    jpegoptim -pqt --strip-all {$base}_thumb.jpg
                    echo "Created {$base}_thumb.jpg"
                end
            end
            
        case favicon
            if test (count $argv) -lt 2
                echo "Error: favicon requires INPUT file"
                return 1
            end
            set -l input $argv[2]
            set -l output "favicon.ico"
            if test (count $argv) -ge 3
                set output $argv[3]
            end
            
            magick convert $input -resize 16x16 -gravity center -crop 16x16+0+0 \
                -flatten -colors 256 -background transparent $output
                
        case '*'
            echo "Error: Unknown operation '$operation'"
            return 1
    end
end
# Backward compatibility wrappers
