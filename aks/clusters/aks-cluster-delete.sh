#!/usr/bin/env bash
#
# aks-cluster-delete.sh - Delete an AKS cluster
# Part of kubernetes-lab (Spec 002: Cloud Platform Standard)
#
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

# Default values
CLUSTER_NAME=""
RESOURCE_GROUP=""
DELETE_RG=false
FORCE=false
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Delete an AKS cluster.

Required:
    --name NAME             Cluster name
    --resource-group RG     Azure resource group

Optional:
    --delete-rg             Also delete the resource group
    --force                 Skip confirmation prompt
    --dry-run               Print commands without executing

    --help                  Show this help message
    --version               Show script version

Examples:
    # Delete cluster (with confirmation)
    $SCRIPT_NAME --name my-cluster --resource-group my-rg

    # Force delete without confirmation
    $SCRIPT_NAME --name my-cluster --resource-group my-rg --force

    # Delete cluster and resource group
    $SCRIPT_NAME --name my-cluster --resource-group my-rg --delete-rg --force
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            --resource-group)
                RESOURCE_GROUP="$2"
                shift 2
                ;;
            --delete-rg)
                DELETE_RG=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            --version)
                echo "$SCRIPT_NAME version $VERSION"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

validate_args() {
    local errors=0

    if [[ -z "$CLUSTER_NAME" ]]; then
        log_error "Cluster name is required (--name)"
        errors=$((errors + 1))
    fi

    if [[ -z "$RESOURCE_GROUP" ]]; then
        log_error "Resource group is required (--resource-group)"
        errors=$((errors + 1))
    fi

    if ! command -v az &> /dev/null; then
        log_error "Azure CLI (az) is not installed"
        errors=$((errors + 1))
    fi

    if [[ $errors -gt 0 ]]; then
        echo ""
        usage
        exit 1
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."

    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Run: az login"
        exit 1
    fi

    log_info "Dependencies check passed"
}

verify_cluster_exists() {
    log_info "Verifying cluster exists..."
    
    if ! az aks show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log_error "Cluster '$CLUSTER_NAME' not found in resource group '$RESOURCE_GROUP'"
        exit 1
    fi

    log_info "Cluster '$CLUSTER_NAME' found"
}

confirm_deletion() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    echo ""
    log_warn "You are about to DELETE cluster: $CLUSTER_NAME"
    log_warn "Resource Group: $RESOURCE_GROUP"
    [[ "$DELETE_RG" == "true" ]] && log_warn "Resource group will ALSO be deleted!"
    echo ""
    
    read -r -p "Are you sure you want to proceed? Type 'yes' to confirm: " response
    if [[ "$response" != "yes" ]]; then
        log_info "Deletion cancelled"
        exit 0
    fi
}

delete_cluster() {
    local cmd="az aks delete --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --yes --no-wait"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute:"
        echo "$cmd"
        return 0
    fi

    log_info "Deleting cluster..."
    eval "$cmd"
}

delete_resource_group() {
    if [[ "$DELETE_RG" != "true" ]]; then
        return 0
    fi

    local cmd="az group delete --name $RESOURCE_GROUP --yes --no-wait"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute:"
        echo "$cmd"
        return 0
    fi

    log_info "Deleting resource group..."
    eval "$cmd"
}

cleanup_kubectl_context() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would clean up kubectl context"
        return 0
    fi

    log_info "Cleaning up kubectl context..."
    
    local context_name="$CLUSTER_NAME"
    if kubectl config get-contexts "$context_name" &> /dev/null; then
        kubectl config delete-context "$context_name" 2>/dev/null || true
        log_info "Removed kubectl context: $context_name"
    fi
}

main() {
    parse_args "$@"
    validate_args
    check_dependencies
    verify_cluster_exists
    confirm_deletion
    delete_cluster
    delete_resource_group
    cleanup_kubectl_context

    log_info "AKS cluster '$CLUSTER_NAME' deletion initiated!"
    log_info "Note: Deletion runs in background. Check Azure portal for progress."
}

main "$@"
