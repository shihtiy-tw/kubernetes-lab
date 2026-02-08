#!/usr/bin/env bash
# Create a basic single-node kind cluster
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create a basic single-node kind cluster for testing.

OPTIONS:
    --name NAME           Cluster name (default: kind-basic)
    --k8s-version VER     Kubernetes version (default: latest)
    --cni CNI             CNI plugin: native, cilium, calico (default: native)
    --wait DURATION       Wait for control plane ready (default: 60s)
    --dry-run             Show what would be created
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Create with default name
    $(basename "$0")

    # Create with custom name
    $(basename "$0") --name my-cluster

    # Create with specific K8s version
    $(basename "$0") --name test --k8s-version v1.29.0

    # Dry run
    $(basename "$0") --name test --dry-run
EOF
}

show_version() {
    echo "$(basename "$0") version ${SCRIPT_VERSION}"
}

# Logging functions (separate stdout/stderr)
log_info() {
    echo "[INFO] $*" >&1
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_warn() {
    echo "[WARN] $*" >&2
}

# Default values
CLUSTER_NAME="kind-basic"
K8S_VERSION=""
CNI_PLUGIN="native"
WAIT_DURATION="60s"
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --k8s-version)
            K8S_VERSION="$2"
            shift 2
            ;;
        --wait)
            WAIT_DURATION="$2"
            shift 2
            ;;
        --cni)
            CNI_PLUGIN="$2"
            if [[ ! "$CNI_PLUGIN" =~ ^(native|cilium|calico)$ ]]; then
                log_error "Invalid CNI: $CNI_PLUGIN. Use: native, cilium, calico"
                exit 1
            fi
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
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

# Check prerequisites
check_prerequisites() {
    if ! command -v kind &> /dev/null; then
        log_error "kind CLI not found. Install: go install sigs.k8s.io/kind@latest"
        exit 2
    fi

    if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
        log_error "Docker or Podman required for kind"
        exit 2
    fi
}

# Generate kind config
generate_config() {
    local config_file="${SCRIPT_DIR}/kind-config.yaml"
    
    cat > "$config_file" << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
nodes:
  - role: control-plane
EOF

    if [[ -n "$K8S_VERSION" ]]; then
        echo "    image: kindest/node:${K8S_VERSION}" >> "$config_file"
    fi

    # Disable default CNI for non-native
    if [[ "$CNI_PLUGIN" != "native" ]]; then
        cat >> "$config_file" << EOF
networking:
  disableDefaultCNI: true
  podSubnet: "10.244.0.0/16"
EOF
    fi

    echo "$config_file"
}

# Main function
main() {
    log_info "Creating kind cluster: ${CLUSTER_NAME}"
    
    check_prerequisites

    # Check if cluster exists
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        log_warn "Cluster '${CLUSTER_NAME}' already exists"
        log_info "Delete it first: kind delete cluster --name ${CLUSTER_NAME}"
        exit 1
    fi

    # Generate config
    local config_file
    config_file=$(generate_config)
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would create cluster with config:"
        cat "$config_file"
        exit 0
    fi

    # Create cluster
    log_info "Creating cluster..."
    if kind create cluster --config "$config_file" --wait "$WAIT_DURATION"; then
        log_info "Cluster '${CLUSTER_NAME}' created successfully"
        
        # Install CNI if not native
        if [[ "$CNI_PLUGIN" == "cilium" ]]; then
            log_info "Installing Cilium CNI..."
            cilium install --wait 2>/dev/null || helm install cilium cilium/cilium --namespace kube-system || log_warn "Cilium install skipped (install manually)"
        elif [[ "$CNI_PLUGIN" == "calico" ]]; then
            log_info "Installing Calico CNI..."
            kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml 2>/dev/null || log_warn "Calico install skipped (install manually)"
        fi
        
        log_info "Context: kind-${CLUSTER_NAME}"
        log_info "Get nodes: kubectl get nodes --context kind-${CLUSTER_NAME}"
        exit 0
    else
        log_error "Failed to create cluster"
        exit 2
    fi
}

main "$@"
