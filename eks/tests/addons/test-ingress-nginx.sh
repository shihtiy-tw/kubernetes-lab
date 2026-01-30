#!/usr/bin/env bash
# Test suite for ingress-nginx-controller addon
# Run BEFORE refactoring to establish baseline, then AFTER to verify

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDON_DIR="$SCRIPT_DIR/../../addons/ingress-nginx-controller"
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

# Test: --help exists and exits 0
test_help_flag() {
    log_test "NGINX-001: --help flag"
    
    if ! grep -q '\-\-help' "$SCRIPT"; then
        log_fail "Script does not contain --help"
        return 1
    fi
    
    if "$SCRIPT" --help > /dev/null 2>&1; then
        log_pass "--help exists and exits 0"
    else
        log_fail "--help missing or exits non-zero"
    fi
}

# Test: --version exists and exits 0
test_version_flag() {
    log_test "NGINX-002: --version flag"
    
    if ! grep -q '\-\-version' "$SCRIPT"; then
        log_fail "Script does not contain --version"
        return 1
    fi
    
    if "$SCRIPT" --version > /dev/null 2>&1; then
        log_pass "--version exists and exits 0"
    else
        log_fail "--version missing or exits non-zero"
    fi
}

# Test: lists versions when invoked with specific flag
test_list_versions() {
    log_test "NGINX-003: --list-versions flag"
    
    if grep -q '\-\-list-versions' "$SCRIPT"; then
        log_pass "--list-versions flag exists"
    else
        log_fail "--list-versions flag missing"
    fi
}

# Test: --dry-run exists
test_dry_run() {
    log_test "NGINX-004: --dry-run flag"
    
    if grep -q '\-\-dry-run' "$SCRIPT"; then
        log_pass "--dry-run flag exists"
    else
        log_fail "--dry-run flag missing"
    fi
}

# Test: invalid flag exits non-zero
test_invalid_flag() {
    log_test "NGINX-005: Invalid flag handling"
    
    if ! "$SCRIPT" --invalid-flag-xyz 2>/dev/null; then
        log_pass "Invalid flag exits non-zero"
    else
        log_fail "Invalid flag should exit non-zero"
    fi
}

# Test: uses set -euo pipefail
test_strict_mode() {
    log_test "NGINX-006: Strict mode (set -euo pipefail)"
    
    if grep -q 'set -euo pipefail' "$SCRIPT"; then
        log_pass "Uses strict mode"
    else
        log_fail "Missing strict mode"
    fi
}

# Test: proper shebang
test_shebang() {
    log_test "NGINX-007: Proper shebang"
    
    local first_line
    first_line=$(head -n1 "$SCRIPT")
    
    if [[ "$first_line" == "#!/usr/bin/env bash" ]]; then
        log_pass "Has #!/usr/bin/env bash"
    else
        log_fail "Should use #!/usr/bin/env bash (got: $first_line)"
    fi
}

# Test: stdout/stderr separation
test_stderr_separation() {
    log_test "NGINX-008: Stdout/stderr separation"
    
    if grep -qE '>&2|log_error.*>&2|echo.*>&2' "$SCRIPT"; then
        log_pass "Has stderr output for errors"
    else
        log_fail "Missing stderr separation for errors"
    fi
}

# Main
main() {
    echo "================================================"
    echo "Test Suite: ingress-nginx-controller"
    echo "Script: $SCRIPT"
    echo "================================================"
    
    if [[ ! -f "$SCRIPT" ]]; then
        echo "ERROR: Script not found: $SCRIPT" >&2
        exit 2
    fi
    
    # Run tests
    test_help_flag || true
    test_version_flag || true
    test_list_versions || true
    test_dry_run || true
    test_invalid_flag || true
    test_strict_mode || true
    test_shebang || true
    test_stderr_separation || true
    
    # Summary
    echo ""
    echo "================================================"
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo "================================================"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}$TESTS_FAILED tests failed${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

main "$@"
