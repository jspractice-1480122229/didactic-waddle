function crypt -d "File encryption and decryption"
    if test (count $argv) -lt 3
        echo "Usage: crypt OPERATION INPUT OUTPUT"
        echo "Operations:"
        echo "  encrypt INPUT OUTPUT - Encrypt file with DES3"
        echo "  decrypt INPUT OUTPUT - Decrypt file with DES3"
        echo "Example: crypt encrypt secret.txt secret.enc"
        return 1
    end

    set -l operation $argv[1]
    set -l input $argv[2]
    set -l output $argv[3]

    if not test -f $input
        echo "Error: Input file '$input' does not exist"
        return 1
    end

    switch $operation
        case encrypt scramble
            echo "Encrypting $input -> $output"
            openssl des3 -salt -in $input -out $output
        case decrypt descramble
            echo "Decrypting $input -> $output"
            openssl des3 -d -in $input -out $output
        case '*'
            echo "Error: Unknown operation '$operation'"
            echo "Valid operations: encrypt, decrypt"
            return 1
    end
end
# Backward compatibility wrappers
