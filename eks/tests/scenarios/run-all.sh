#!/usr/bin/env bash
# Run all scenario tests
# Reports baseline compliance before refactoring

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}EKS Scenarios CLI 12-Factor Compliance Report${NC}"
echo -e "${BLUE}Date: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}================================================${NC}"

SCENARIOS_PASSED=0
SCENARIOS_FAILED=0
SCENARIOS_TOTAL=0

# Find all scenario scripts
find_scenario_scripts() {
    find "$SCRIPT_DIR/../../scenarios" -name "*.sh" -type f 2>/dev/null || true
}

# Test a single scenario script
test_script() {
    local script="$1"
    local script_name
    script_name=$(basename "$script")
    local scenario_name
    scenario_name=$(dirname "$script" | xargs basename)
    
    ((SCENARIOS_TOTAL++))
    
    echo -e "\n${YELLOW}Testing:${NC} $scenario_name/$script_name"
    
    local checks=0
    local passed=0
    
    # Check 1: Has --help
    ((checks++))
    if grep -q '\-\-help' "$script" 2>/dev/null; then
        ((passed++))
    fi
    
    # Check 2: Has --version
    ((checks++))
    if grep -q '\-\-version' "$script" 2>/dev/null; then
        ((passed++))
    fi
    
    # Check 3: Has strict mode
    ((checks++))
    if grep -q 'set -e' "$script" 2>/dev/null; then
        ((passed++))
    fi
    
    # Check 4: Has proper shebang
    ((checks++))
    if head -n1 "$script" | grep -qE '#!/usr/bin/env bash|#!/bin/bash' 2>/dev/null; then
        ((passed++))
    fi
    
    # Check 5: --help works (only if it exists)
    if grep -q '\-\-help' "$script" 2>/dev/null; then
        ((checks++))
        if "$script" --help > /dev/null 2>&1; then
            ((passed++))
        fi
    fi
    
    # Report
    if [[ $passed -eq $checks ]]; then
        echo -e "  ${GREEN}✓${NC} $passed/$checks checks passed - COMPLIANT"
        ((SCENARIOS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $passed/$checks checks passed - NEEDS REFACTORING"
        ((SCENARIOS_FAILED++))
    fi
}

# Run all tests
mapfile -t SCRIPTS < <(find_scenario_scripts)

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        test_script "$script"
    fi
done

# Summary
echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "Total Scenarios Tested:  $SCENARIOS_TOTAL"
echo -e "Compliant:               ${GREEN}$SCENARIOS_PASSED${NC}"
echo -e "Need Refactoring:        ${RED}$SCENARIOS_FAILED${NC}"
