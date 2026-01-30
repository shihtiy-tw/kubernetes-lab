#!/usr/bin/env bash
# Test suite for cluster-autoscaler addon
# Run BEFORE refactoring to establish baseline, then AFTER to verify

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDON_DIR="$SCRIPT_DIR/../../addons/cluster-autoscaler"
SCRIPT="$ADDON_DIR/build.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_test() { echo -e "\n${YELLOW}TEST:${NC} $*"; }
log_pass() { echo -e "  ${GREEN}✓${NC} $*"; ((TESTS_PASSED++)); ((TESTS_RUN++)); }
log_fail() { echo -e "  ${RED}✗${NC} $*"; ((TESTS_FAILED++)); ((TESTS_RUN++)); }

test_help_flag() {
    log_test "CA-001: --help flag"
    if grep -q '\-\-help' "$SCRIPT" && "$SCRIPT" --help > /dev/null 2>&1; then
        log_pass "--help exists and exits 0"
    else
        log_fail "--help missing or exits non-zero"
    fi
}

test_version_flag() {
    log_test "CA-002: --version flag"
    if grep -q '\-\-version' "$SCRIPT" && "$SCRIPT" --version > /dev/null 2>&1; then
        log_pass "--version exists and exits 0"
    else
        log_fail "--version missing or exits non-zero"
    fi
}

test_cluster_flag() {
    log_test "CA-003: --cluster flag"
    if grep -q '\-\-cluster' "$SCRIPT"; then
        log_pass "--cluster flag exists"
    else
        log_fail "--cluster flag missing"
    fi
}

test_dry_run() {
    log_test "CA-004: --dry-run flag"
    if grep -q '\-\-dry-run' "$SCRIPT"; then
        log_pass "--dry-run flag exists"
    else
        log_fail "--dry-run flag missing"
    fi
}

test_invalid_flag() {
    log_test "CA-005: Invalid flag handling"
    if ! "$SCRIPT" --invalid-flag-xyz 2>/dev/null; then
        log_pass "Invalid flag exits non-zero"
    else
        log_fail "Invalid flag should exit non-zero"
    fi
}

test_strict_mode() {
    log_test "CA-006: Strict mode"
    if grep -q 'set -euo pipefail' "$SCRIPT"; then
        log_pass "Uses strict mode"
    else
        log_fail "Missing strict mode"
    fi
}

main() {
    echo "================================================"
    echo "Test Suite: cluster-autoscaler"
    echo "Script: $SCRIPT"
    echo "================================================"
    
    if [[ ! -f "$SCRIPT" ]]; then
        echo "ERROR: Script not found: $SCRIPT" >&2
        exit 2
    fi
    
    test_help_flag || true
    test_version_flag || true
    test_cluster_flag || true
    test_dry_run || true
    test_invalid_flag || true
    test_strict_mode || true
    
    echo ""
    echo "================================================"
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo "================================================"
    
    [[ $TESTS_FAILED -gt 0 ]] && exit 1 || exit 0
}

main "$@"
