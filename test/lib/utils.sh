#!/bin/sh

ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

error() {
    echo "${RED}x ERROR: $1${NC}"
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo "${YELLOW}! WARNING: $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

success() {
    echo "${GREEN}+ $1${NC}"
}

info() {
    echo "- $1"
}
