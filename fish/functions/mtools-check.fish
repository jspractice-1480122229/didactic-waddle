function mtools-check
    echo "=== Checking mtools configuration ==="

    if not test -f /etc/mtools.conf
        echo "❌ No mtoolsrc found. Create one first."
        return 1
    end

    echo "✓ /etc/mtools.conf exists"
    echo ""
    echo "Contents:"
    cat /etc/mtools.conf

    echo ""
    echo "=== Testing mtools drives ==="
    minfo u: 2>&1 || echo "❌ Drive u: not accessible"
    echo ""
end
