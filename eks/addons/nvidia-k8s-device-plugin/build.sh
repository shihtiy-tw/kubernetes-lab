#!/usr/bin/env bash
# NVIDIA K8s Device Plugin installation for Kubernetes
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

Install NVIDIA Kubernetes Device Plugin on a cluster.

OPTIONS:
    --chart-version VER   Helm chart version (default: latest)
    --namespace NS        Namespace (default: kube-system)
    --values FILE         Custom values file
    --list-versions       List available chart versions and exit
    --dry-run             Show what would be installed
    --uninstall           Uninstall the plugin
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # List available versions
    $(basename "$0") --list-versions

    # Install latest version
    $(basename "$0")

    # Install with custom values
    $(basename "$0") --values nvdp-values.yaml

    # Install specific version
    $(basename "$0") --chart-version 0.14.0

    # Dry run
    $(basename "$0") --dry-run
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
REPO_NAME="nvdp"
REPO_URL="https://nvidia.github.io/k8s-device-plugin"
CHART_NAME="nvidia-device-plugin"
RELEASE_NAME="nvdp"

# Defaults
CHART_VERSION=""
APP_VERSION=""
NAMESPACE="kube-system"
VALUES_FILE=""
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

# Add/update Helm repo
setup_repo() {
    log_step "Helm Repository"
    helm repo add "$REPO_NAME" "$REPO_URL" > /dev/null 2>&1 || true
    helm repo update "$REPO_NAME" > /dev/null 2>&1
    log_success "Repository ready: $REPO_NAME"
}

# List available versions
list_versions() {
    setup_repo
    log_step "Available Chart Versions"
    echo -e "${GREEN}CHART VERSION   APP VERSION${NC}"
    helm search repo "${REPO_NAME}/${CHART_NAME}" --versions --output json | \
        jq -r '.[] | "\(.version)\t\(.app_version)"' | head -n 15
}

# Get latest versions
get_latest_versions() {
    local versions
    versions=$(helm search repo "${REPO_NAME}/${CHART_NAME}" --versions --output json)
    CHART_VERSION=$(echo "$versions" | jq -r '.[0].version')
    APP_VERSION=$(echo "$versions" | jq -r '.[0].app_version')
}

# Uninstall
uninstall() {
    log_step "Uninstalling NVIDIA Device Plugin"
    
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        if $DRY_RUN; then
            log_info "[DRY RUN] Would uninstall $RELEASE_NAME from $NAMESPACE"
        else
            helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
            log_success "Uninstalled NVIDIA Device Plugin"
        fi
    else
        log_warn "$RELEASE_NAME not found in $NAMESPACE"
    fi
    exit 0
}

# Main installation
main() {
    # Handle uninstall
    if $UNINSTALL; then
        setup_repo
        uninstall
    fi

    # List versions mode
    if $LIST_VERSIONS; then
        list_versions
        exit 0
    fi

    # Setup repo
    setup_repo

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
        log_info "Would install NVIDIA Device Plugin"
        log_info "  Chart Version: $CHART_VERSION"
        log_info "  Namespace: $NAMESPACE"
        [[ -n "$VALUES_FILE" ]] && log_info "  Values File: $VALUES_FILE"
        exit 0
    fi

    # Build helm arguments
    local helm_args=(
        upgrade --install "$RELEASE_NAME"
        "${REPO_NAME}/${CHART_NAME}"
        --namespace "$NAMESPACE"
        --create-namespace
        --version "$CHART_VERSION"
    )

    # Add values file if specified
    if [[ -n "$VALUES_FILE" ]]; then
        if [[ -f "$VALUES_FILE" ]]; then
            helm_args+=(-f "$VALUES_FILE")
            log_info "Using values file: $VALUES_FILE"
        elif [[ -f "${SCRIPT_DIR}/${VALUES_FILE}" ]]; then
            helm_args+=(-f "${SCRIPT_DIR}/${VALUES_FILE}")
            log_info "Using values file: ${SCRIPT_DIR}/${VALUES_FILE}"
        else
            log_warn "Values file not found: $VALUES_FILE"
        fi
    fi

    # Install/Upgrade
    log_step "Installing NVIDIA Device Plugin"
    helm "${helm_args[@]}"

    log_success "NVIDIA Device Plugin installed"
    
    log_step "Verification"
    helm list -n "$NAMESPACE" --filter "$RELEASE_NAME"
    
    log_info "Installation complete!"
    log_info "Check DaemonSet: kubectl get daemonset -n $NAMESPACE -l app.kubernetes.io/name=nvidia-device-plugin"
    exit 0
}

main "$@"
