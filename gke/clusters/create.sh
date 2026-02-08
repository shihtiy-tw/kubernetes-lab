#!/usr/bin/env bash
# Create GKE cluster with CNI support
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="1.0.0"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create a GKE cluster with optional CNI configuration.

OPTIONS:
    --name NAME           Cluster name (required)
    --project PROJECT     GCP project ID (required or set GOOGLE_PROJECT)
    --region REGION       GCP region (default: us-central1)
    --k8s-version VER     Kubernetes version (default: latest)
    --cni CNI             CNI plugin: dpv2, calico (default: dpv2)
    --dry-run             Show what would be created
    -h, --help            Show this help message

EXAMPLES:
    # Create with Dataplane V2 (default)
    $(basename "$0") --name my-cluster --project my-project

    # Create with Calico
    $(basename "$0") --name my-cluster --project my-project --cni calico
EOF
}

log_info() { echo "[INFO] $*" >&1; }
log_error() { echo "[ERROR] $*" >&2; }

# Defaults
CLUSTER_NAME=""
PROJECT="${GOOGLE_PROJECT:-}"
REGION="us-central1"
K8S_VERSION=""
CNI_PLUGIN="dpv2"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name) CLUSTER_NAME="$2"; shift 2 ;;
        --project) PROJECT="$2"; shift 2 ;;
        --region) REGION="$2"; shift 2 ;;
        --k8s-version) K8S_VERSION="$2"; shift 2 ;;
        --cni)
            CNI_PLUGIN="$2"
            if [[ ! "$CNI_PLUGIN" =~ ^(dpv2|calico)$ ]]; then
                log_error "Invalid CNI: $CNI_PLUGIN. Use: dpv2, calico"
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
[[ -z "$PROJECT" ]] && { log_error "--project or GOOGLE_PROJECT required"; exit 1; }

main() {
    local cmd="gcloud container clusters create $CLUSTER_NAME"
    cmd+=" --project $PROJECT --region $REGION --num-nodes 2"
    
    if [[ "$CNI_PLUGIN" == "dpv2" ]]; then
        cmd+=" --enable-dataplane-v2"
    elif [[ "$CNI_PLUGIN" == "calico" ]]; then
        cmd+=" --enable-network-policy"
    fi
    
    [[ -n "$K8S_VERSION" ]] && cmd+=" --cluster-version $K8S_VERSION"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would execute: $cmd"
        exit 0
    fi
    
    log_info "Creating GKE cluster..."
    eval "$cmd"
    
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT"
    log_info "Cluster created and kubeconfig updated"
}

main "$@"
