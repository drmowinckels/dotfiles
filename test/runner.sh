#!/bin/sh

echo "================================"
echo "Testing Dotfiles Configuration"
echo "================================"
echo ""

DOTFILES="$HOME/.dotfiles"
TEST_DIR="$DOTFILES/test"

. "$TEST_DIR/lib/utils.sh"

for test_file in "$TEST_DIR/tests/"*.sh; do
    . "$test_file"
    echo ""
done

echo "================================"
echo "Test Results"
echo "================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "${GREEN}All tests passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "${YELLOW}Tests passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo "${RED}Tests failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
