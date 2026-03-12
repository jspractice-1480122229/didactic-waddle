#!/usr/bin/env fish
# Test script for fstr function
# Tests all practical usage scenarios

# Color codes for output
set -l RED '\033[0;31m'
set -l GREEN '\033[0;32m'
set -l YELLOW '\033[1;33m'
set -l NC '\033[0m' # No Color

function print_test_header
    echo ""
    echo "=========================================="
    echo -e "$YELLOW TEST: $argv[1] $NC"
    echo "=========================================="
end

function print_command
    echo -e "$GREEN Running: $argv $NC"
end

# Setup test environment
set -l test_dir "/tmp/fstr_test_"(random)
mkdir -p $test_dir
cd $test_dir

# Create test files with various content
echo "This is a test file with IAGO in it" > test_file.txt
echo "iago lowercase here" >> test_file.txt
echo "Another line with Iago mixed case" >> test_file.txt

echo "IAGO appears here too" > TEST_FILE.TXT
echo "Multiple IAGO IAGO entries" >> TEST_FILE.TXT

echo "finder function mentioned" > finder_doc.md
echo "The finder tool is useful" >> finder_doc.md

echo "No matching content here" > empty_match.txt
echo "Just some random text" >> empty_match.txt

echo "Python code: import os" > script.py
echo "Python code: import sys" >> script.py

mkdir -p subdir
echo "iago in subdirectory" > subdir/nested.txt
echo "finder in nested file" > subdir/nested_finder.txt

echo -e "\n$GREEN Test environment created at: $test_dir $NC"
echo "Files created:"
ls -la

# Test 1: Basic search (case-sensitive)
print_test_header "Basic case-sensitive search"
print_command "fstr iago"
fstr iago

# Test 2: Case-insensitive search
print_test_header "Case-insensitive search with -i flag"
print_command "fstr -i iago"
fstr -i iago

# Test 3: Search with file pattern (case-sensitive)
print_test_header "Case-sensitive with file pattern"
print_command "fstr iago test_file"
fstr iago test_file

# Test 4: Case-insensitive with file pattern
print_test_header "Case-insensitive with file pattern"
print_command "fstr -i iago test_file"
fstr -i iago test_file

# Test 5: File pattern matching different case
print_test_header "File pattern with different case (should match due to -iname)"
print_command "fstr -i iago TEST_FILE"
fstr -i iago TEST_FILE

# Test 6: No color output
print_test_header "No color output with -nc flag"
print_command "fstr -nc iago"
fstr -nc iago

# Test 7: No color with --no-color flag
print_test_header "No color output with --no-color flag"
print_command "fstr --no-color iago"
fstr --no-color iago

# Test 8: Debug mode
print_test_header "Debug mode showing internal calls"
print_command "fstr --debug iago"
fstr --debug iago

# Test 9: Debug + no color
print_test_header "Debug mode with no color"
print_command "fstr --debug -nc iago"
fstr --debug -nc iago

# Test 10: Debug + case-insensitive
print_test_header "Debug mode with case-insensitive search"
print_command "fstr --debug -i IAGO"
fstr --debug -i IAGO

# Test 11: All flags combined
print_test_header "All flags: debug, no-color, case-insensitive, with file pattern"
print_command "fstr --debug --no-color -i iago test_file"
fstr --debug --no-color -i iago test_file

# Test 12: Search for 'finder'
print_test_header "Search for 'finder' term"
print_command "fstr finder"
fstr finder

# Test 13: Search with .md extension pattern
print_test_header "Search in markdown files only"
print_command "fstr finder .md"
fstr finder .md

# Test 14: Search in .py files
print_test_header "Search in Python files"
print_command "fstr -i python .py"
fstr -i python .py

# Test 15: No matches scenario
print_test_header "Search with no matches"
print_command "fstr NONEXISTENT"
fstr NONEXISTENT

# Test 16: Empty pattern (should show usage)
print_test_header "Empty pattern (error handling)"
print_command "fstr"
fstr

# Test 17: Only -i flag (should show error)
print_test_header "Only -i flag without pattern (error handling)"
print_command "fstr -i"
fstr -i

# Test 18: Search in subdirectories
print_test_header "Search includes subdirectories"
print_command "fstr -i iago"
fstr -i iago

# Test 19: Case-sensitive uppercase search
print_test_header "Case-sensitive UPPERCASE search"
print_command "fstr IAGO"
fstr IAGO

# Test 20: Mixed flags order
print_test_header "Mixed flag order (should still work)"
print_command "fstr -i --debug -nc iago"
fstr -i --debug -nc iago

# Cleanup
echo ""
echo "=========================================="
echo -e "$YELLOW Cleaning up test environment $NC"
echo "=========================================="
cd /tmp
rm -rf $test_dir
echo -e "$GREEN Test directory removed: $test_dir $NC"

echo ""
echo "=========================================="
echo -e "$GREEN ALL TESTS COMPLETE $NC"
echo "=========================================="
