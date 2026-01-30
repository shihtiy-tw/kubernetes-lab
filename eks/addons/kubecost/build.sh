#!/usr/bin/env bash
# Kubecost installation for EKS
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

Install Kubecost cost monitoring on a Kubernetes cluster.

OPTIONS:
    --chart-version VER   Helm chart version (default: latest)
    --namespace NS        Namespace (default: kubecost)
    --values FILE         Custom values file
    --eks-optimized       Use EKS-optimized values (default: true)
    --list-versions       Show latest version info
    --dry-run             Show what would be installed
    --uninstall           Uninstall Kubecost
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Install latest version
    $(basename "$0")

    # Install specific version
    $(basename "$0") --chart-version 2.0.0

    # Dry run
    $(basename "$0") --dry-run

    # Install with custom values
    $(basename "$0") --values custom-values.yaml
EOF
}

show_version() {
    echo "$(basename "$0") version ${SCRIPT_VERSION}"
}

# Logging - separate stdout/stderr
log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&1; }
log_success() { echo -e "${GREEN}[OK]${NC} $*" >&1; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "\n${YELLOW}=== $* ===${NC}" >&1; }

# Configuration
CHART_URL="oci://public.ecr.aws/kubecost/cost-analyzer"
EKS_VALUES_URL="https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/develop/cost-analyzer/values-eks-cost-monitoring.yaml"

# Defaults
CHART_VERSION=""
APP_VERSION=""
NAMESPACE="kubecost"
VALUES_FILE=""
EKS_OPTIMIZED=true
LIST_VERSIONS=false
DRY_RUN=false
UNINSTALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --chart-version)
            CHART_VERSION="$2"
            shift 2
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --values)
            VALUES_FILE="$2"
            shift 2
            ;;
        --eks-optimized)
            EKS_OPTIMIZED=true
            shift
            ;;
        --no-eks-optimized)
            EKS_OPTIMIZED=false
            shift
            ;;
        --list-versions)
            LIST_VERSIONS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
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

# Get latest version from OCI registry
get_latest_versions() {
    log_info "Fetching latest version from OCI registry..."
    local chart_info
    chart_info=$(helm show chart "$CHART_URL" 2>/dev/null)
    CHART_VERSION=$(echo "$chart_info" | grep '^version:' | awk '{print $2}')
    APP_VERSION=$(echo "$chart_info" | grep '^appVersion:' | awk '{print $2}')
}

# List versions
list_versions() {
    get_latest_versions
    log_step "Latest Kubecost Versions"
    echo -e "${GREEN}Chart Version: ${CHART_VERSION}${NC}"
    echo -e "${GREEN}App Version:   ${APP_VERSION}${NC}"
    log_info "For all versions, visit: https://gallery.ecr.aws/kubecost/cost-analyzer"
}

# Uninstall
uninstall() {
    log_step "Uninstalling Kubecost"
    
    if helm list -n "$NAMESPACE" | grep -q "kubecost"; then
        if $DRY_RUN; then
            log_info "[DRY RUN] Would uninstall kubecost from $NAMESPACE"
        else
            helm uninstall kubecost -n "$NAMESPACE"
            log_success "Uninstalled Kubecost"
        fi
    else
        log_warn "Kubecost not found in $NAMESPACE"
    fi
    exit 0
}

# Main installation
main() {
    # Handle uninstall
    if $UNINSTALL; then
        uninstall
    fi

    # List versions mode
    if $LIST_VERSIONS; then
        list_versions
        exit 0
    fi

    # Get versions
    if [[ -z "$CHART_VERSION" ]]; then
        get_latest_versions
        log_info "Using latest: chart=$CHART_VERSION app=$APP_VERSION"
    else
        [[ -z "$APP_VERSION" ]] && APP_VERSION="$CHART_VERSION"
        log_info "Using specified: chart=$CHART_VERSION"
    fi

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would install Kubecost"
        log_info "  Chart Version: $CHART_VERSION"
        log_info "  Namespace: $NAMESPACE"
        log_info "  EKS Optimized: $EKS_OPTIMIZED"
        [[ -n "$VALUES_FILE" ]] && log_info "  Values File: $VALUES_FILE"
        exit 0
    fi

    # Build helm arguments
    local helm_args=(
        upgrade --install kubecost
        "$CHART_URL"
        --version "$CHART_VERSION"
        --namespace "$NAMESPACE"
        --create-namespace
    )

    # Add EKS-optimized values
    if $EKS_OPTIMIZED; then
        helm_args+=(-f "$EKS_VALUES_URL")
        log_info "Using EKS-optimized values"
    fi

    # Add custom values file
    if [[ -n "$VALUES_FILE" ]]; then
        if [[ -f "$VALUES_FILE" ]]; then
            helm_args+=(-f "$VALUES_FILE")
            log_info "Using custom values: $VALUES_FILE"
        else
            log_error "Values file not found: $VALUES_FILE"
            exit 1
        fi
    fi

    # Install/Upgrade
    log_step "Installing Kubecost"
    helm "${helm_args[@]}"

    log_success "Kubecost installed"
    
    log_step "Verification"
    helm list -n "$NAMESPACE" --filter kubecost
    
    log_info "Installation complete!"
    log_info "Access UI: kubectl port-forward -n $NAMESPACE svc/kubecost-cost-analyzer 9090:9090"
    exit 0
}

main "$@"
