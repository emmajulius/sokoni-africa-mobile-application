#!/usr/bin/env bash
# Run all tests for Sokoni Africa App

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🧪 Running tests for Sokoni Africa App..."
echo "=========================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

# Run Flutter tests
echo -e "${BLUE}Running Flutter unit tests...${NC}"
cd "$REPO_ROOT"
if flutter test; then
    echo -e "${GREEN}✓ All Flutter unit tests passed${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Flutter unit tests failed${NC}"
    ((FAILED++))
fi
echo ""

# Run Flutter integration tests (if they exist)
if [ -d "integration_test" ] && [ "$(ls -A integration_test)" ]; then
    echo -e "${BLUE}Running Flutter integration tests...${NC}"
    if flutter test integration_test; then
        echo -e "${GREEN}✓ All Flutter integration tests passed${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ Flutter integration tests failed${NC}"
        ((FAILED++))
    fi
    echo ""
fi

# Run backend tests
echo -e "${BLUE}Running backend API tests...${NC}"
cd "$REPO_ROOT/africa_sokoni_app_backend"

# Activate virtual environment
if [ -d ".venv" ]; then
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        source .venv/Scripts/activate
    else
        source .venv/bin/activate
    fi
fi

# Check if pytest is installed
if python -c "import pytest" 2>/dev/null; then
    # Check if test directory exists
    if [ -d "tests" ] && [ "$(ls -A tests)" ]; then
        if pytest -v; then
            echo -e "${GREEN}✓ All backend tests passed${NC}"
            ((PASSED++))
        else
            echo -e "${RED}✗ Backend tests failed${NC}"
            ((FAILED++))
        fi
    else
        echo -e "${BLUE}ℹ No backend tests found (tests/ directory is empty or missing)${NC}"
    fi
else
    echo -e "${BLUE}ℹ pytest not installed. Install with: pip install pytest${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo -e "Test Summary:"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed: $FAILED${NC}"
    exit 1
else
    echo -e "  ${GREEN}Failed: $FAILED${NC}"
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
fi

