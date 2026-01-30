#!/usr/bin/env bash
# Secrets Store CSI Driver installation for Kubernetes
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

Install Secrets Store CSI Driver on a Kubernetes cluster.

OPTIONS:
    --chart-version VER   Helm chart version (default: latest)
    --namespace NS        Namespace (default: kube-system)
    --with-aws-provider   Also install AWS Secrets Manager provider
    --list-versions       List available chart versions and exit
    --dry-run             Show what would be installed
    --uninstall           Uninstall the driver
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # List available versions
    $(basename "$0") --list-versions

    # Install latest version
    $(basename "$0")

    # Install with AWS provider
    $(basename "$0") --with-aws-provider

    # Install specific version
    $(basename "$0") --chart-version 1.4.0

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
REPO_NAME="secrets-store-csi-driver"
REPO_URL="https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
CHART_NAME="secrets-store-csi-driver"
RELEASE_NAME="csi-secrets-store"

# Defaults
CHART_VERSION=""
APP_VERSION=""
NAMESPACE="kube-system"
WITH_AWS_PROVIDER=false
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
        --with-aws-provider)
            WITH_AWS_PROVIDER=true
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
    log_step "Uninstalling Secrets Store CSI Driver"
    
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        if $DRY_RUN; then
            log_info "[DRY RUN] Would uninstall $RELEASE_NAME from $NAMESPACE"
        else
            helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
            log_success "Uninstalled Secrets Store CSI Driver"
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
        log_info "Would install Secrets Store CSI Driver"
        log_info "  Chart Version: $CHART_VERSION"
        log_info "  Namespace: $NAMESPACE"
        log_info "  AWS Provider: $WITH_AWS_PROVIDER"
        exit 0
    fi

    # Install/Upgrade
    log_step "Installing Secrets Store CSI Driver"
    
    helm upgrade --install "$RELEASE_NAME" \
        "${REPO_NAME}/${CHART_NAME}" \
        --namespace "$NAMESPACE" \
        --version "$CHART_VERSION" \
        --set syncSecret.enabled=true

    log_success "Secrets Store CSI Driver installed"

    # Install AWS provider if requested
    if $WITH_AWS_PROVIDER; then
        log_step "Installing AWS Secrets Manager Provider"
        kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml
        log_success "AWS provider installed"
    fi
    
    log_step "Verification"
    helm list -n "$NAMESPACE" --filter "$RELEASE_NAME"
    
    log_info "Installation complete!"
    log_info "Create SecretProviderClass resources to use secrets"
    exit 0
}

main "$@"
