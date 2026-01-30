#!/usr/bin/env bash
# Create a kind cluster with ingress ports exposed
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create a kind cluster pre-configured for ingress testing.
Exposes ports 80 and 443 on localhost.

OPTIONS:
    --name NAME           Cluster name (default: kind-ingress)
    --k8s-version VER     Kubernetes version (default: latest)
    --wait DURATION       Wait duration (default: 120s)
    --dry-run             Show what would be created
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    $(basename "$0")
    $(basename "$0") --name ingress-test
    $(basename "$0") --dry-run
EOF
}

show_version() {
    echo "$(basename "$0") version ${SCRIPT_VERSION}"
}

log_info() { echo "[INFO] $*" >&1; }
log_error() { echo "[ERROR] $*" >&2; }
log_warn() { echo "[WARN] $*" >&2; }

CLUSTER_NAME="kind-ingress"
K8S_VERSION=""
WAIT_DURATION="120s"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name) CLUSTER_NAME="$2"; shift 2 ;;
        --k8s-version) K8S_VERSION="$2"; shift 2 ;;
        --wait) WAIT_DURATION="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        -v|--version) show_version; exit 0 ;;
        *) log_error "Unknown: $1"; exit 1 ;;
    esac
done

check_prerequisites() {
    command -v kind &> /dev/null || { log_error "kind CLI not found"; exit 2; }
}

generate_config() {
    local config_file="${SCRIPT_DIR}/kind-config.yaml"
    local node_image=""
    
    [[ -n "$K8S_VERSION" ]] && node_image="  image: kindest/node:${K8S_VERSION}"
    
    cat > "$config_file" << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
nodes:
  - role: control-plane
${node_image}
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
EOF

    echo "$config_file"
}

main() {
    log_info "Creating ingress-ready kind cluster: ${CLUSTER_NAME}"
    
    check_prerequisites

    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        log_warn "Cluster '${CLUSTER_NAME}' already exists"
        exit 1
    fi

    local config_file
    config_file=$(generate_config)
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Config:"
        cat "$config_file"
        exit 0
    fi

    if kind create cluster --config "$config_file" --wait "$WAIT_DURATION"; then
        log_info "Cluster '${CLUSTER_NAME}' created"
        log_info "Ports 80 and 443 mapped to localhost"
        log_info "Install ingress: kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml"
        exit 0
    else
        log_error "Failed to create cluster"
        exit 2
    fi
}

main "$@"
