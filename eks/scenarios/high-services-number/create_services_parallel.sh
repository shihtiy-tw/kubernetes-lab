#!/usr/bin/env bash
# Create High Number of Services Scenario
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

Create a high number of Kubernetes services for testing.

OPTIONS:
    --start N             Starting service number (default: 1)
    --end N               Ending service number (default: 1000)
    --parallel N          Number of parallel jobs (default: 50)
    --namespace NS        Namespace (default: default)
    --dry-run             Show what would be created
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Create 1000 services
    $(basename "$0") --start 1 --end 1000

    # Create 5000 services with high parallelism
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

# Create service function
create_service() {
    local i=$1
    local ns=$2
    cat <<EOF | kubectl apply -f - 2>/dev/null
apiVersion: v1
kind: Service
metadata:
  name: my-service-$i
  namespace: $ns
spec:
  selector:
    app: MyApp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 9376
EOF
}
export -f create_service

# Main
main() {
    local total=$((END - START + 1))
    
    log_step "Configuration"
    log_info "Range: $START to $END ($total services)"
    log_info "Parallelism: $PARALLEL"
    log_info "Namespace: $NAMESPACE"

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would create $total services"
        log_info "Services: my-service-$START to my-service-$END"
        exit 0
    fi

    log_step "Creating Services"
    log_info "This may take a while..."
    
    seq "$START" "$END" | xargs -n 1 -P "$PARALLEL" -I {} bash -c "create_service {} $NAMESPACE"

    log_success "$total services created"

    log_step "Complete"
    log_info "Check services: kubectl get svc -n $NAMESPACE | wc -l"
    exit 0
}

main "$@"
