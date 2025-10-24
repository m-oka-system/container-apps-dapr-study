#!/bin/bash

# TFLint - Check all Terraform directories
# Usage: ./scripts/tflint-all.sh

set -e

echo "🔍 Running TFLint on all Terraform directories..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
PASSED=0
FAILED=0

# Function to run tflint on a directory
run_tflint() {
    local dir=$1
    local label=$2

    TOTAL=$((TOTAL + 1))

    echo "📁 Checking: ${label}"
    echo "   Path: ${dir}"

    if [ ! -d "$dir" ]; then
        echo -e "   ${YELLOW}⚠️  Directory not found, skipping${NC}"
        echo ""
        return
    fi

    cd "$dir"

    # Initialize TFLint if needed
    if [ ! -d ".tflint.d" ]; then
        echo "   Initializing TFLint..."
        tflint --init > /dev/null 2>&1 || true
    fi

    # Run TFLint
    if tflint --format=compact 2>&1; then
        echo -e "   ${GREEN}✅ Passed${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "   ${RED}❌ Failed${NC}"
        FAILED=$((FAILED + 1))
    fi

    echo ""
    cd - > /dev/null
}

# Get the repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Check main infrastructure directory
run_tflint "$REPO_ROOT/infra" "Main Infrastructure"

# Check if there are environment-specific directories
# (Uncomment and adjust paths as needed)
# run_tflint "$REPO_ROOT/terraform/env/dev" "Development Environment"
# run_tflint "$REPO_ROOT/terraform/env/prod" "Production Environment"

# Check if there are module directories
# run_tflint "$REPO_ROOT/terraform/modules/vnet" "VNet Module"
# run_tflint "$REPO_ROOT/terraform/modules/aks" "AKS Module"

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 TFLint Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Total directories: $TOTAL"
echo -e "   ${GREEN}Passed: $PASSED${NC}"
echo -e "   ${RED}Failed: $FAILED${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAILED -gt 0 ]; then
    exit 1
fi

echo -e "${GREEN}✨ All checks passed!${NC}"
