#!/usr/bin/env bash
#
# aks-nodepool-create.sh - Create an AKS node pool
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
NODEPOOL_NAME=""
CLUSTER_NAME=""
RESOURCE_GROUP=""
NODE_COUNT=2
MIN_COUNT=""
MAX_COUNT=""
VM_SIZE="Standard_DS2_v2"
OS_TYPE="Linux"
LABELS=""
TAINTS=""
SPOT=false
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Create an AKS node pool.

Required:
    --name NAME                 Node pool name
    --cluster CLUSTER           Cluster name
    --resource-group RG         Azure resource group

Optional:
    --node-count N              Initial node count (default: 2)
    --min-count N               Minimum nodes for autoscaling
    --max-count N               Maximum nodes for autoscaling
    --vm-size SIZE              VM size (default: Standard_DS2_v2)
    --os-type TYPE              OS type: Linux, Windows (default: Linux)
    --labels KEY=VAL,...        Node labels (comma-separated)
    --taints KEY=VAL:EFF        Node taints
    --spot                      Use Spot VMs
    --dry-run                   Print commands without executing

    --help                      Show this help message
    --version                   Show script version

Examples:
    # Basic node pool
    $SCRIPT_NAME --name pool1 --cluster my-cluster --resource-group my-rg

    # Spot node pool with autoscaling
    $SCRIPT_NAME --name spot-pool --cluster my-cluster --resource-group my-rg \
        --spot --min-count 0 --max-count 10

    # Windows node pool
    $SCRIPT_NAME --name winpool --cluster my-cluster --resource-group my-rg \
        --os-type Windows --vm-size Standard_D4s_v3
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)
                NODEPOOL_NAME="$2"
                shift 2
                ;;
            --cluster)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            --resource-group)
                RESOURCE_GROUP="$2"
                shift 2
                ;;
            --node-count)
                NODE_COUNT="$2"
                shift 2
                ;;
            --min-count)
                MIN_COUNT="$2"
                shift 2
                ;;
            --max-count)
                MAX_COUNT="$2"
                shift 2
                ;;
            --vm-size)
                VM_SIZE="$2"
                shift 2
                ;;
            --os-type)
                OS_TYPE="$2"
                shift 2
                ;;
            --labels)
                LABELS="$2"
                shift 2
                ;;
            --taints)
                TAINTS="$2"
                shift 2
                ;;
            --spot)
                SPOT=true
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

    if [[ -z "$NODEPOOL_NAME" ]]; then
        log_error "Node pool name is required (--name)"
        errors=$((errors + 1))
    fi

    if [[ -z "$CLUSTER_NAME" ]]; then
        log_error "Cluster name is required (--cluster)"
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
        usage
        exit 1
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."

    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure"
        exit 1
    fi

    log_info "Dependencies check passed"
}

build_command() {
    local cmd="az aks nodepool add"
    cmd="$cmd --name $NODEPOOL_NAME"
    cmd="$cmd --cluster-name $CLUSTER_NAME"
    cmd="$cmd --resource-group $RESOURCE_GROUP"
    cmd="$cmd --node-count $NODE_COUNT"
    cmd="$cmd --node-vm-size $VM_SIZE"
    cmd="$cmd --os-type $OS_TYPE"

    # Autoscaling
    if [[ -n "$MIN_COUNT" && -n "$MAX_COUNT" ]]; then
        cmd="$cmd --enable-cluster-autoscaler --min-count $MIN_COUNT --max-count $MAX_COUNT"
    fi

    # Labels
    if [[ -n "$LABELS" ]]; then
        cmd="$cmd --labels $LABELS"
    fi

    # Taints
    if [[ -n "$TAINTS" ]]; then
        cmd="$cmd --node-taints $TAINTS"
    fi

    # Spot VMs
    if [[ "$SPOT" == "true" ]]; then
        cmd="$cmd --priority Spot --eviction-policy Delete --spot-max-price -1"
    fi

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

main() {
    parse_args "$@"
    validate_args
    check_dependencies

    log_info "Creating node pool: $NODEPOOL_NAME"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "VM size: $VM_SIZE"
    [[ "$SPOT" == "true" ]] && log_info "Using Spot VMs"

    local cmd
    cmd=$(build_command)
    run_command "$cmd"

    log_info "Node pool '$NODEPOOL_NAME' created successfully!"
}

main "$@"
