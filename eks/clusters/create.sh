#!/usr/bin/env bash
# Create EKS cluster with CNI support
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create an EKS cluster with optional CNI configuration.

OPTIONS:
    --name NAME           Cluster name (required)
    --region REGION       AWS region (default: us-east-1)
    --k8s-version VER     Kubernetes version (default: 1.29)
    --cni CNI             CNI plugin: vpc, cilium, calico (default: vpc)
    --config FILE         Use eksctl config file
    --dry-run             Show what would be created
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Create with VPC CNI (default)
    $(basename "$0") --name my-cluster

    # Create with Cilium
    $(basename "$0") --name my-cluster --cni cilium

    # Use config file
    $(basename "$0") --config eksctl-cluster-minimal.yaml
EOF
}

log_info() { echo "[INFO] $*" >&1; }
log_error() { echo "[ERROR] $*" >&2; }
log_warn() { echo "[WARN] $*" >&2; }

# Defaults
CLUSTER_NAME=""
REGION="${AWS_REGION:-us-east-1}"
K8S_VERSION="1.29"
CNI_PLUGIN="vpc"
CONFIG_FILE=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name) CLUSTER_NAME="$2"; shift 2 ;;
        --region) REGION="$2"; shift 2 ;;
        --k8s-version) K8S_VERSION="$2"; shift 2 ;;
        --cni)
            CNI_PLUGIN="$2"
            if [[ ! "$CNI_PLUGIN" =~ ^(vpc|cilium|calico)$ ]]; then
                log_error "Invalid CNI: $CNI_PLUGIN. Use: vpc, cilium, calico"
                exit 1
            fi
            shift 2
            ;;
        --config) CONFIG_FILE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        -v|--version) echo "$SCRIPT_VERSION"; exit 0 ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

# Validation
if [[ -z "$CLUSTER_NAME" && -z "$CONFIG_FILE" ]]; then
    log_error "Either --name or --config is required"
    exit 1
fi

# Check prerequisites
if ! command -v eksctl &> /dev/null; then
    log_error "eksctl not found. Install: https://eksctl.io/"
    exit 2
fi

main() {
    local cmd="eksctl create cluster"
    
    if [[ -n "$CONFIG_FILE" ]]; then
        cmd+=" --config-file $CONFIG_FILE"
    else
        cmd+=" --name $CLUSTER_NAME --region $REGION --version $K8S_VERSION"
        
        # CNI configuration
        if [[ "$CNI_PLUGIN" != "vpc" ]]; then
            cmd+=" --without-nodegroup"
            log_info "Note: Non-VPC CNI selected. Install CNI after cluster creation."
        fi
    fi
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would execute: $cmd"
        exit 0
    fi
    
    log_info "Creating EKS cluster..."
    eval "$cmd"
    
    # Post-install CNI
    if [[ "$CNI_PLUGIN" == "cilium" ]]; then
        log_info "Installing Cilium CNI..."
        cilium install --wait || log_warn "Install Cilium manually"
    elif [[ "$CNI_PLUGIN" == "calico" ]]; then
        log_info "Installing Calico CNI..."
        kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml || log_warn "Install Calico manually"
    fi
    
    log_info "Cluster created successfully"
}

main "$@"
