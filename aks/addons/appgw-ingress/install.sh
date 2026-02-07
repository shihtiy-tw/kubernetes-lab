#!/usr/bin/env bash
#
# install.sh - Install Azure Application Gateway Ingress Controller
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
APPGW_NAME=""
APPGW_SUBNET=""
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Install Application Gateway Ingress Controller (AGIC) on AKS.

Required:
    --cluster CLUSTER           AKS cluster name
    --resource-group RG         Azure resource group
    --appgw-name NAME           Application Gateway name (will create if not exists)
    --appgw-subnet SUBNET       Subnet ID or name for App Gateway

Optional:
    --dry-run                   Print commands without executing

    --help                      Show this help message
    --version                   Show script version

Examples:
    $SCRIPT_NAME --cluster my-aks --resource-group my-rg \
        --appgw-name my-appgw --appgw-subnet appgw-subnet
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
            --appgw-name)
                APPGW_NAME="$2"
                shift 2
                ;;
            --appgw-subnet)
                APPGW_SUBNET="$2"
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

    if [[ -z "$APPGW_NAME" ]]; then
        log_error "Application Gateway name is required (--appgw-name)"
        errors=$((errors + 1))
    fi

    if [[ -z "$APPGW_SUBNET" ]]; then
        log_error "Application Gateway subnet is required (--appgw-subnet)"
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

enable_agic_addon() {
    log_info "Enabling AGIC addon on AKS cluster..."

    local cmd="az aks enable-addons"
    cmd="$cmd --name $CLUSTER_NAME"
    cmd="$cmd --resource-group $RESOURCE_GROUP"
    cmd="$cmd --addon ingress-appgw"
    cmd="$cmd --appgw-name $APPGW_NAME"
    cmd="$cmd --appgw-subnet-id $APPGW_SUBNET"

    run_cmd "$cmd"
}

main() {
    parse_args "$@"
    validate_args
    check_dependencies

    log_info "Installing Application Gateway Ingress Controller..."
    log_info "Cluster: $CLUSTER_NAME"
    log_info "App Gateway: $APPGW_NAME"

    enable_agic_addon

    log_info "AGIC installed successfully!"
    log_info "Use 'kubernetes.io/ingress.class: azure/application-gateway' annotation in your Ingress resources"
}

main "$@"
