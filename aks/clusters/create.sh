#!/usr/bin/env bash
# Create AKS cluster with CNI support
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="1.0.0"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create an AKS cluster with optional CNI configuration.

OPTIONS:
    --name NAME           Cluster name (required)
    --resource-group RG   Azure resource group (required)
    --location LOC        Azure location (default: eastus)
    --k8s-version VER     Kubernetes version (default: latest)
    --cni CNI             CNI plugin: azure, cilium, calico (default: azure)
    --dry-run             Show what would be created
    -h, --help            Show this help message

EXAMPLES:
    # Create with Azure CNI (default)
    $(basename "$0") --name my-cluster --resource-group my-rg

    # Create with Cilium
    $(basename "$0") --name my-cluster --resource-group my-rg --cni cilium
EOF
}

log_info() { echo "[INFO] $*" >&1; }
log_error() { echo "[ERROR] $*" >&2; }

# Defaults
CLUSTER_NAME=""
RESOURCE_GROUP=""
LOCATION="eastus"
K8S_VERSION=""
CNI_PLUGIN="azure"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name) CLUSTER_NAME="$2"; shift 2 ;;
        --resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
        --location) LOCATION="$2"; shift 2 ;;
        --k8s-version) K8S_VERSION="$2"; shift 2 ;;
        --cni)
            CNI_PLUGIN="$2"
            if [[ ! "$CNI_PLUGIN" =~ ^(azure|cilium|calico)$ ]]; then
                log_error "Invalid CNI: $CNI_PLUGIN. Use: azure, cilium, calico"
                exit 1
            fi
            shift 2
            ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

[[ -z "$CLUSTER_NAME" ]] && { log_error "--name required"; exit 1; }
[[ -z "$RESOURCE_GROUP" ]] && { log_error "--resource-group required"; exit 1; }

main() {
    local cmd="az aks create --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP"
    cmd+=" --location $LOCATION --node-count 2 --generate-ssh-keys"
    
    if [[ "$CNI_PLUGIN" == "azure" ]]; then
        cmd+=" --network-plugin azure"
    elif [[ "$CNI_PLUGIN" == "cilium" ]]; then
        cmd+=" --network-plugin none"  # BYO CNI
    elif [[ "$CNI_PLUGIN" == "calico" ]]; then
        cmd+=" --network-plugin azure --network-policy calico"
    fi
    
    [[ -n "$K8S_VERSION" ]] && cmd+=" --kubernetes-version $K8S_VERSION"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would execute: $cmd"
        exit 0
    fi
    
    log_info "Creating AKS cluster..."
    eval "$cmd"
    
    az aks get-credentials --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --overwrite-existing
    
    if [[ "$CNI_PLUGIN" == "cilium" ]]; then
        log_info "Installing Cilium CNI..."
        cilium install --wait || log_info "Install Cilium manually"
    fi
    
    log_info "Cluster created and kubeconfig updated"
}

main "$@"
