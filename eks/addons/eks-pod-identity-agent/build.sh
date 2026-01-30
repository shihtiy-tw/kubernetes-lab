#!/usr/bin/env bash
# EKS Pod Identity Agent installation (via EKS Addon)
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

Install EKS Pod Identity Agent on an EKS cluster as an EKS Addon.

OPTIONS:
    --addon-version VER   Addon version (default: latest)
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --list-versions       List available addon versions and exit
    --dry-run             Show what would be installed
    --uninstall           Uninstall the addon
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # List available versions
    $(basename "$0") --list-versions

    # Install latest version
    $(basename "$0")

    # Install specific version
    $(basename "$0") --addon-version v1.2.0-eksbuild.1

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
ADDON_NAME="eks-pod-identity-agent"

# Defaults
ADDON_VERSION=""
CLUSTER_NAME=""
REGION=""
LIST_VERSIONS=false
DRY_RUN=false
UNINSTALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --addon-version)
            ADDON_VERSION="$2"
            shift 2
            ;;
        --cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
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

# Get cluster info from context if not provided
get_cluster_info() {
    if [[ -z "$CLUSTER_NAME" ]] || [[ -z "$REGION" ]]; then
        local context
        context=$(kubectl config current-context)
        
        if [[ -z "$CLUSTER_NAME" ]]; then
            CLUSTER_NAME=$(echo "$context" | awk -F: '{split($NF,a,"/"); print a[2]}')
        fi
        
        if [[ -z "$REGION" ]]; then
            REGION=$(echo "$context" | awk -F: '{print $4}')
        fi
    fi
    
    CLUSTER_VERSION=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query 'cluster.version' --output text)
}

# Get latest addon version
get_latest_version() {
    aws eks describe-addon-versions \
        --addon-name "$ADDON_NAME" \
        --kubernetes-version "$CLUSTER_VERSION" \
        --query 'addons[].addonVersions[].addonVersion' \
        --output text | tr '\t' '\n' | sort -V | tail -n 1
}

# List available versions
list_versions() {
    get_cluster_info
    log_step "Available Addon Versions (EKS $CLUSTER_VERSION)"
    aws eks describe-addon-versions \
        --addon-name "$ADDON_NAME" \
        --kubernetes-version "$CLUSTER_VERSION" \
        --query 'addons[].addonVersions[].addonVersion' \
        --output table
}

# Uninstall
uninstall() {
    log_step "Uninstalling Pod Identity Agent"
    
    if aws eks list-addons --cluster-name "$CLUSTER_NAME" --region "$REGION" --output text | grep -q "$ADDON_NAME"; then
        if $DRY_RUN; then
            log_info "[DRY RUN] Would delete addon $ADDON_NAME"
        else
            aws eks delete-addon \
                --cluster-name "$CLUSTER_NAME" \
                --addon-name "$ADDON_NAME" \
                --region "$REGION"
            log_success "Addon deleted"
        fi
    else
        log_warn "$ADDON_NAME addon not found"
    fi
    exit 0
}

# Main installation
main() {
    # Handle uninstall
    if $UNINSTALL; then
        get_cluster_info
        uninstall
    fi

    # List versions mode
    if $LIST_VERSIONS; then
        list_versions
        exit 0
    fi

    # Get cluster info
    get_cluster_info
    
    log_step "Environment"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $REGION"
    log_info "K8s Version: $CLUSTER_VERSION"

    # Get version
    if [[ -z "$ADDON_VERSION" ]]; then
        ADDON_VERSION=$(get_latest_version)
        log_info "Using latest: $ADDON_VERSION"
    else
        log_info "Using specified: $ADDON_VERSION"
    fi

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would install Pod Identity Agent"
        log_info "  Addon Version: $ADDON_VERSION"
        log_info "  Cluster: $CLUSTER_NAME"
        exit 0
    fi

    # Install/Update addon
    log_step "Installing Pod Identity Agent"
    
    if aws eks list-addons --cluster-name "$CLUSTER_NAME" --region "$REGION" --output text | grep -q "$ADDON_NAME"; then
        log_info "Updating existing addon..."
        
        aws eks update-addon \
            --cluster-name "$CLUSTER_NAME" \
            --region "$REGION" \
            --addon-name "$ADDON_NAME" \
            --addon-version "$ADDON_VERSION" \
            --resolve-conflicts OVERWRITE
        log_success "Addon updated"
    else
        log_info "Creating new addon..."
        
        aws eks create-addon \
            --cluster-name "$CLUSTER_NAME" \
            --region "$REGION" \
            --addon-name "$ADDON_NAME" \
            --addon-version "$ADDON_VERSION" \
            --resolve-conflicts OVERWRITE
        log_success "Addon created"
    fi

    log_step "Verification"
    aws eks describe-addon \
        --cluster-name "$CLUSTER_NAME" \
        --addon-name "$ADDON_NAME" \
        --region "$REGION" \
        --query 'addon.{Name:addonName,Version:addonVersion,Status:status}' \
        --output table
    
    log_info "Installation complete!"
    log_info "Check pods: kubectl get pods -n kube-system -l app.kubernetes.io/name=eks-pod-identity-agent"
    exit 0
}

main "$@"
