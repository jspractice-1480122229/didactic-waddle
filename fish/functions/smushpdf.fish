function smushpdf -d "Shrink PDF files"
    if test (count $argv) -ne 2
        echo "Usage: smushpdf INPUT.pdf OUTPUT.pdf"
        echo "Example: smushpdf big_document.pdf small_document.pdf"
        return 1
    end
    
    if not test -f $argv[1]
        echo "Error: Input file '$argv[1]' does not exist"
        return 1
    end
    
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE \
       -dBATCH -dQUIET -sOutputFile=$argv[2] $argv[1]
end
