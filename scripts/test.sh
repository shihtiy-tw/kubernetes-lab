#!/usr/bin/env bash
# Spec 004: Scenario Test Runner
# Wrapper for KUTTL test execution
set -euo pipefail

VERSION="1.0.0"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCENARIO=""
SUITE=""
CNI=""
DRY_RUN=false

usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --scenario PATH    Run a single scenario (e.g., scenarios/general/pod-basic)"
    echo "  --suite NAME       Run all scenarios in a suite (general, network, eks, gke, aks)"
    echo "  --cni NAME         Filter scenarios by CNI requirement (cilium, calico, native)"
    echo "  --dry-run          Show what would be tested without running"
    echo "  --version          Show version"
    echo "  --help             Show this help"
}

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --scenario) SCENARIO="$2"; shift 2 ;;
        --suite) SUITE="$2"; shift 2 ;;
        --cni) CNI="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --version) echo "$VERSION"; exit 0 ;;
        --help) usage; exit 0 ;;
        *) log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# Check KUTTL is installed
if ! command -v kubectl-kuttl &>/dev/null && ! kubectl kuttl version &>/dev/null; then
    log_error "KUTTL not found. Install with: kubectl krew install kuttl"
    exit 1
fi

run_test() {
    local path="$1"
    log_info "Running: $path"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] kubectl kuttl test $path"
    else
        kubectl kuttl test "$path" --skip-cluster-delete
    fi
}

if [[ -n "$SCENARIO" ]]; then
    if [[ ! -d "$SCENARIO" ]]; then
        log_error "Scenario not found: $SCENARIO"
        exit 1
    fi
    run_test "$SCENARIO"
elif [[ -n "$SUITE" ]]; then
    SUITE_PATH="scenarios/$SUITE"
    if [[ ! -d "$SUITE_PATH" ]]; then
        log_error "Suite not found: $SUITE_PATH"
        exit 1
    fi
    log_info "Running suite: $SUITE"
    for scenario in "$SUITE_PATH"/*/; do
        if [[ -f "${scenario}kuttl-test.yaml" ]]; then
            run_test "$scenario"
        fi
    done
else
    log_error "Must specify --scenario or --suite"
    usage
    exit 1
fi

log_info "Tests complete!"
