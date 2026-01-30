#!/usr/bin/env bash
# Create a multi-node kind cluster (1 control-plane + 2 workers)
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create a multi-node kind cluster for realistic testing.

OPTIONS:
    --name NAME           Cluster name (default: kind-multi)
    --workers N           Number of worker nodes (default: 2)
    --k8s-version VER     Kubernetes version (default: latest)
    --wait DURATION       Wait for control plane ready (default: 120s)
    --dry-run             Show what would be created
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Create with defaults (2 workers)
    $(basename "$0")

    # Create with 3 workers
    $(basename "$0") --name large --workers 3

    # Dry run
    $(basename "$0") --dry-run
EOF
}

show_version() {
    echo "$(basename "$0") version ${SCRIPT_VERSION}"
}

log_info() { echo "[INFO] $*" >&1; }
log_error() { echo "[ERROR] $*" >&2; }
log_warn() { echo "[WARN] $*" >&2; }

# Defaults
CLUSTER_NAME="kind-multi"
WORKERS=2
K8S_VERSION=""
WAIT_DURATION="120s"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name) CLUSTER_NAME="$2"; shift 2 ;;
        --workers) WORKERS="$2"; shift 2 ;;
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
    
    [[ -n "$K8S_VERSION" ]] && node_image="    image: kindest/node:${K8S_VERSION}"
    
    cat > "$config_file" << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
nodes:
  - role: control-plane
${node_image}
EOF

    for ((i=1; i<=WORKERS; i++)); do
        cat >> "$config_file" << EOF
  - role: worker
${node_image}
EOF
    done

    echo "$config_file"
}

main() {
    log_info "Creating multi-node kind cluster: ${CLUSTER_NAME}"
    log_info "Workers: ${WORKERS}"
    
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
        log_info "Context: kind-${CLUSTER_NAME}"
        exit 0
    else
        log_error "Failed to create cluster"
        exit 2
    fi
}

main "$@"
