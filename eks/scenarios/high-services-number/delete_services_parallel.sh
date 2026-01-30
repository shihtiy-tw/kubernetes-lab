#!/usr/bin/env bash
# Delete High Number of Services Scenario
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Delete a high number of Kubernetes services.

OPTIONS:
    --start N             Starting service number (default: 1)
    --end N               Ending service number (default: 1000)
    --parallel N          Number of parallel jobs (default: 50)
    --namespace NS        Namespace (default: default)
    --dry-run             Show what would be deleted
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Delete services 1-1000
    $(basename "$0") --start 1 --end 1000

    # Delete services with high parallelism
    $(basename "$0") --start 1 --end 5000 --parallel 100

    # Dry run
    $(basename "$0") --dry-run
EOF
}

show_version() {
    echo "$(basename "$0") version ${SCRIPT_VERSION}"
}

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&1; }
log_success() { echo -e "${GREEN}[OK]${NC} $*" >&1; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "\n${YELLOW}=== $* ===${NC}" >&1; }

# Defaults
START=1
END=1000
PARALLEL=50
NAMESPACE="default"
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --start)
            START="$2"
            shift 2
            ;;
        --end)
            END="$2"
            shift 2
            ;;
        --parallel)
            PARALLEL="$2"
            shift 2
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Run '$(basename "$0") --help' for usage." >&2
            exit 1
            ;;
    esac
done

# Delete service function
delete_service() {
    local i=$1
    local ns=$2
    kubectl delete service "my-service-$i" -n "$ns" 2>/dev/null || true
}
export -f delete_service

# Main
main() {
    local total=$((END - START + 1))
    
    log_step "Configuration"
    log_info "Range: $START to $END ($total services)"
    log_info "Parallelism: $PARALLEL"
    log_info "Namespace: $NAMESPACE"

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would delete $total services"
        log_info "Services: my-service-$START to my-service-$END"
        exit 0
    fi

    log_step "Deleting Services"
    log_info "This may take a while..."
    
    seq "$START" "$END" | xargs -n 1 -P "$PARALLEL" -I {} bash -c "delete_service {} $NAMESPACE"

    log_success "$total services deleted"

    log_step "Complete"
    log_info "Check services: kubectl get svc -n $NAMESPACE | wc -l"
    exit 0
}

main "$@"
