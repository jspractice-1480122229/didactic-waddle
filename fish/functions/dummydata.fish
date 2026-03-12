function dummydata -d "Create files with random data"
    if test (count $argv) -ne 2
        echo "Usage: dummydata FILENAME SIZE"
        echo "Example: dummydata testfile.dat 1024"
        echo "Creates FILENAME with SIZE bytes of random data"
        return 1
    end
    
    head -c $argv[2] </dev/urandom > $argv[1]
end
