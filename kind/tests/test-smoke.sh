#!/usr/bin/env bash
# Smoke test for kind cluster and shared plugins
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="1.0.0"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Run smoke tests to verify cluster and basic functionality.

OPTIONS:
    --context CONTEXT     Kubectl context (default: current)
    --namespace NS        Test namespace (default: smoke-test)
    --verbose             Show detailed output
    --dry-run             Show what would be tested
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    $(basename "$0")
    $(basename "$0") --context kind-basic
    $(basename "$0") --verbose
EOF
}

show_version() {
    echo "$(basename "$0") version ${SCRIPT_VERSION}"
}

log_info() { echo "[INFO] $*" >&1; }
log_error() { echo "[ERROR] $*" >&2; }
log_pass() { echo "[PASS] $*" >&1; }
log_fail() { echo "[FAIL] $*" >&2; }

CONTEXT=""
NAMESPACE="smoke-test"
VERBOSE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --context) CONTEXT="$2"; shift 2 ;;
        --namespace) NAMESPACE="$2"; shift 2 ;;
        --verbose) VERBOSE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        -v|--version) show_version; exit 0 ;;
        *) log_error "Unknown: $1"; exit 1 ;;
    esac
done

KUBECTL="kubectl"
[[ -n "$CONTEXT" ]] && KUBECTL="kubectl --context $CONTEXT"

run_test() {
    local name="$1"
    local cmd="$2"
    
    if $VERBOSE; then
        log_info "Running: $cmd"
    fi
    
    if eval "$cmd" > /dev/null 2>&1; then
        log_pass "$name"
        return 0
    else
        log_fail "$name"
        return 1
    fi
}

main() {
    log_info "Running smoke tests"
    [[ -n "$CONTEXT" ]] && log_info "Context: $CONTEXT"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Tests to run:"
        echo "  - Cluster connectivity"
        echo "  - API server health"
        echo "  - Node readiness"
        echo "  - CoreDNS running"
        echo "  - Pod scheduling"
        exit 0
    fi

    local failed=0

    # Test 1: Cluster connectivity
    run_test "Cluster connectivity" "$KUBECTL cluster-info" || ((failed++))

    # Test 2: API server health
    run_test "API server health" "$KUBECTL get --raw /healthz" || ((failed++))

    # Test 3: Node readiness
    run_test "Nodes ready" "$KUBECTL get nodes -o jsonpath='{.items[*].status.conditions[?(@.type==\"Ready\")].status}' | grep -q True" || ((failed++))

    # Test 4: CoreDNS running
    run_test "CoreDNS running" "$KUBECTL get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[0].status.phase}' | grep -q Running" || ((failed++))

    # Test 5: Create test namespace
    run_test "Create namespace" "$KUBECTL create namespace $NAMESPACE --dry-run=client -o yaml | $KUBECTL apply -f -" || ((failed++))

    # Test 6: Schedule a pod
    run_test "Pod scheduling" "$KUBECTL run smoke-test --image=busybox --restart=Never -n $NAMESPACE --command -- sleep 5 --dry-run=client -o yaml | $KUBECTL apply -f - && sleep 3 && $KUBECTL delete pod smoke-test -n $NAMESPACE --ignore-not-found" || ((failed++))

    # Cleanup
    $KUBECTL delete namespace "$NAMESPACE" --ignore-not-found > /dev/null 2>&1 || true

    log_info "---"
    if [[ $failed -eq 0 ]]; then
        log_info "All tests passed!"
        exit 0
    else
        log_error "$failed test(s) failed"
        exit 1
    fi
}

main "$@"
