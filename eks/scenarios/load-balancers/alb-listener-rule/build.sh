#!/usr/bin/env bash
# ALB Listener Rule Scenario
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

Deploy ALB with custom listener rules.

OPTIONS:
    --apply               Apply the configuration (default)
    --delete              Delete the configuration
    --dry-run             Show what would be deployed
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Deploy
    $(basename "$0")

    # Dry run
    $(basename "$0") --dry-run

    # Delete
    $(basename "$0") --delete
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
ACTION="apply"
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --apply)
            ACTION="apply"
            shift
            ;;
        --delete)
            ACTION="delete"
            shift
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

# Main
main() {
    cd "$SCRIPT_DIR"

    log_step "Action: $ACTION"

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would $ACTION Kustomize configuration"
        exit 0
    fi

    if [[ "$ACTION" == "delete" ]]; then
        log_step "Deleting Resources"
        kustomize build . | kubectl delete -f - 2>/dev/null || true
        log_success "Resources deleted"
    else
        log_step "Applying Resources"
        kustomize build . | kubectl apply -f -
        log_success "Resources applied"
    fi

    log_step "Complete"
    log_info "Check ingress: kubectl get ingress"
    exit 0
}

main "$@"
