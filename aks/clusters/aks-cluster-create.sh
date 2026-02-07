#!/usr/bin/env bash
#
# aks-cluster-create.sh - Create an AKS cluster
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
LOCATION=""
NODE_COUNT=2
VM_SIZE="Standard_DS2_v2"
K8S_VERSION=""
NETWORK_PLUGIN="azure"
ENABLE_PRIVATE=""
ENABLE_AAD=""
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Create an AKS cluster with standard configuration.

Required:
    --name NAME                 Cluster name
    --resource-group RG         Azure resource group
    --location LOCATION         Azure region (e.g., eastus)

Optional:
    --node-count N              Initial node count (default: 2)
    --vm-size SIZE              VM size (default: Standard_DS2_v2)
    --k8s-version VERSION       Kubernetes version
    --network-plugin PLUGIN     Network plugin: azure, kubenet (default: azure)
    --private                   Enable private cluster
    --enable-aad                Enable Azure AD integration
    --dry-run                   Print commands without executing

    --help                      Show this help message
    --version                   Show script version

Examples:
    # Basic cluster
    $SCRIPT_NAME --name my-cluster --resource-group my-rg --location eastus

    # With custom settings
    $SCRIPT_NAME --name prod-cluster --resource-group prod-rg --location westus2 \
        --node-count 3 --vm-size Standard_D4s_v3 --enable-aad

    # Dry run
    $SCRIPT_NAME --name test --resource-group test-rg --location eastus --dry-run
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
            --location)
                LOCATION="$2"
                shift 2
                ;;
            --node-count)
                NODE_COUNT="$2"
                shift 2
                ;;
            --vm-size)
                VM_SIZE="$2"
                shift 2
                ;;
            --k8s-version)
                K8S_VERSION="$2"
                shift 2
                ;;
            --network-plugin)
                NETWORK_PLUGIN="$2"
                shift 2
                ;;
            --private)
                ENABLE_PRIVATE="--enable-private-cluster"
                shift
                ;;
            --enable-aad)
                ENABLE_AAD="--enable-aad --enable-azure-rbac"
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

    if [[ -z "$LOCATION" ]]; then
        log_error "Location is required (--location)"
        errors=$((errors + 1))
    fi

    if ! command -v az &> /dev/null; then
        log_error "Azure CLI (az) is not installed. See: https://docs.microsoft.com/cli/azure/install-azure-cli"
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

    # Check Azure CLI login
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Run: az login"
        exit 1
    fi

    log_info "Logged in as: $(az account show --query user.name -o tsv)"
    log_info "Subscription: $(az account show --query name -o tsv)"

    log_info "Dependencies check passed"
}

create_resource_group() {
    log_info "Checking resource group..."

    if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        log_info "Resource group '$RESOURCE_GROUP' already exists"
    else
        log_info "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
        local cmd="az group create --name $RESOURCE_GROUP --location $LOCATION"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] $cmd"
        else
            eval "$cmd"
        fi
    fi
}

build_command() {
    local cmd="az aks create"
    cmd="$cmd --name $CLUSTER_NAME"
    cmd="$cmd --resource-group $RESOURCE_GROUP"
    cmd="$cmd --location $LOCATION"
    cmd="$cmd --node-count $NODE_COUNT"
    cmd="$cmd --node-vm-size $VM_SIZE"
    cmd="$cmd --network-plugin $NETWORK_PLUGIN"
    cmd="$cmd --generate-ssh-keys"

    if [[ -n "$K8S_VERSION" ]]; then
        cmd="$cmd --kubernetes-version $K8S_VERSION"
    fi

    if [[ -n "$ENABLE_PRIVATE" ]]; then
        cmd="$cmd $ENABLE_PRIVATE"
    fi

    if [[ -n "$ENABLE_AAD" ]]; then
        cmd="$cmd $ENABLE_AAD"
    fi

    # Standard settings
    cmd="$cmd --enable-cluster-autoscaler --min-count 1 --max-count 10"
    cmd="$cmd --enable-managed-identity"

    echo "$cmd"
}

run_command() {
    local cmd="$1"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute:"
        echo "$cmd"
        return 0
    fi

    log_info "Executing: $cmd"
    eval "$cmd"
}

configure_kubectl() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would configure kubectl"
        return 0
    fi

    log_info "Configuring kubectl context..."
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
    
    log_info "kubectl configured. Current context:"
    kubectl config current-context
}

main() {
    parse_args "$@"
    validate_args
    check_dependencies

    log_info "Creating AKS cluster: $CLUSTER_NAME"
    log_info "Resource Group: $RESOURCE_GROUP"
    log_info "Location: $LOCATION"
    log_info "Node count: $NODE_COUNT"
    log_info "VM size: $VM_SIZE"

    create_resource_group

    local cmd
    cmd=$(build_command)
    run_command "$cmd"

    configure_kubectl

    log_info "AKS cluster '$CLUSTER_NAME' created successfully!"
}

main "$@"
