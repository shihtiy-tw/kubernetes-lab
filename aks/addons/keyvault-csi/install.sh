#!/usr/bin/env bash
#
# install.sh - Configure Azure Key Vault CSI Driver
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

# Required values
CLUSTER_NAME=""
RESOURCE_GROUP=""
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Enable Azure Key Vault CSI Driver addon on AKS.

Required:
    --cluster CLUSTER           AKS cluster name
    --resource-group RG         Azure resource group

Optional:
    --dry-run                   Print commands without executing

    --help                      Show this help message
    --version                   Show script version

Examples:
    $SCRIPT_NAME --cluster my-aks --resource-group my-rg
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cluster)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            --resource-group)
                RESOURCE_GROUP="$2"
                shift 2
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
        log_error "Cluster name is required (--cluster)"
        errors=$((errors + 1))
    fi

    if [[ -z "$RESOURCE_GROUP" ]]; then
        log_error "Resource group is required (--resource-group)"
        errors=$((errors + 1))
    fi

    if [[ $errors -gt 0 ]]; then
        usage
        exit 1
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v az &> /dev/null; then
        log_error "Azure CLI (az) is not installed"
        exit 1
    fi

    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure"
        exit 1
    fi

    log_info "Dependencies check passed"
}

run_cmd() {
    local cmd="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] $cmd"
    else
        eval "$cmd"
    fi
}

enable_keyvault_csi() {
    log_info "Enabling Key Vault CSI Driver addon..."

    local cmd="az aks enable-addons"
    cmd="$cmd --name $CLUSTER_NAME"
    cmd="$cmd --resource-group $RESOURCE_GROUP"
    cmd="$cmd --addon azure-keyvault-secrets-provider"

    run_cmd "$cmd"
}

main() {
    parse_args "$@"
    validate_args
    check_dependencies

    log_info "Enabling Azure Key Vault CSI Driver..."
    log_info "Cluster: $CLUSTER_NAME"

    enable_keyvault_csi

    log_info "Key Vault CSI Driver enabled successfully!"
    log_info "Create SecretProviderClass resources to sync secrets from Key Vault"
}

main "$@"
