#!/usr/bin/env bash
#
# gke-nodepool-create.sh - Create a GKE node pool
# Part of kubernetes-lab (Spec 002: Cloud Platform Standard)
#
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info()  { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

# Default values
NODEPOOL_NAME=""
CLUSTER_NAME=""
REGION=""
ZONE=""
PROJECT=""
NODE_COUNT=2
MIN_NODES=""
MAX_NODES=""
MACHINE_TYPE="e2-medium"
DISK_SIZE=100
DISK_TYPE="pd-standard"
LABELS=""
TAINTS=""
SPOT=false
PREEMPTIBLE=false
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Create a GKE node pool.

Required:
    --name NAME             Node pool name
    --cluster CLUSTER       Cluster name
    --region REGION         GCP region (for regional cluster)
                            OR
    --zone ZONE             GCP zone (for zonal cluster)

Optional:
    --project PROJECT       GCP project ID (defaults to gcloud config)
    --node-count N          Initial node count per zone (default: 2)
    --min-nodes N           Minimum nodes for autoscaling
    --max-nodes N           Maximum nodes for autoscaling
    --machine-type TYPE     Machine type (default: e2-medium)
    --disk-size GB          Boot disk size in GB (default: 100)
    --disk-type TYPE        Disk type: pd-standard, pd-ssd, pd-balanced (default: pd-standard)
    --labels KEY=VAL,...    Node labels (comma-separated)
    --taints KEY=VAL:EFF    Node taints (comma-separated, effect: NoSchedule|PreferNoSchedule|NoExecute)
    --spot                  Use Spot VMs
    --preemptible           Use preemptible VMs (legacy, prefer --spot)
    --dry-run               Print commands without executing

    --help                  Show this help message
    --version               Show script version

Examples:
    # Basic node pool
    $SCRIPT_NAME --name pool-1 --cluster my-cluster --region us-central1

    # Autoscaling node pool with Spot VMs
    $SCRIPT_NAME --name spot-pool --cluster my-cluster --region us-central1 \
        --min-nodes 0 --max-nodes 10 --spot

    # Node pool with labels and taints
    $SCRIPT_NAME --name gpu-pool --cluster my-cluster --zone us-central1-a \
        --machine-type n1-standard-4 \
        --labels "workload=gpu,team=ml" \
        --taints "gpu=true:NoSchedule"
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
            --region)
                REGION="$2"
                shift 2
                ;;
            --zone)
                ZONE="$2"
                shift 2
                ;;
            --project)
                PROJECT="$2"
                shift 2
                ;;
            --node-count)
                NODE_COUNT="$2"
                shift 2
                ;;
            --min-nodes)
                MIN_NODES="$2"
                shift 2
                ;;
            --max-nodes)
                MAX_NODES="$2"
                shift 2
                ;;
            --machine-type)
                MACHINE_TYPE="$2"
                shift 2
                ;;
            --disk-size)
                DISK_SIZE="$2"
                shift 2
                ;;
            --disk-type)
                DISK_TYPE="$2"
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
            --preemptible)
                PREEMPTIBLE=true
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

    if [[ -z "$REGION" && -z "$ZONE" ]]; then
        log_error "Either --region or --zone is required"
        errors=$((errors + 1))
    fi

    if [[ -n "$REGION" && -n "$ZONE" ]]; then
        log_error "Cannot specify both --region and --zone"
        errors=$((errors + 1))
    fi

    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed"
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

    if ! gcloud auth print-access-token &> /dev/null; then
        log_error "Not authenticated with gcloud"
        exit 1
    fi

    if [[ -z "$PROJECT" ]]; then
        PROJECT=$(gcloud config get-value project 2>/dev/null)
        if [[ -z "$PROJECT" ]]; then
            log_error "No project specified"
            exit 1
        fi
        log_info "Using project: $PROJECT"
    fi

    log_info "Dependencies check passed"
}

build_command() {
    local cmd="gcloud container node-pools create $NODEPOOL_NAME"
    cmd="$cmd --cluster $CLUSTER_NAME"
    
    # Location
    if [[ -n "$REGION" ]]; then
        cmd="$cmd --region $REGION"
    else
        cmd="$cmd --zone $ZONE"
    fi

    cmd="$cmd --project $PROJECT"
    cmd="$cmd --num-nodes $NODE_COUNT"
    cmd="$cmd --machine-type $MACHINE_TYPE"
    cmd="$cmd --disk-size $DISK_SIZE"
    cmd="$cmd --disk-type $DISK_TYPE"

    # Autoscaling
    if [[ -n "$MIN_NODES" && -n "$MAX_NODES" ]]; then
        cmd="$cmd --enable-autoscaling --min-nodes $MIN_NODES --max-nodes $MAX_NODES"
    fi

    # Labels
    if [[ -n "$LABELS" ]]; then
        cmd="$cmd --node-labels=$LABELS"
    fi

    # Taints
    if [[ -n "$TAINTS" ]]; then
        cmd="$cmd --node-taints=$TAINTS"
    fi

    # Spot/Preemptible
    if [[ "$SPOT" == "true" ]]; then
        cmd="$cmd --spot"
    elif [[ "$PREEMPTIBLE" == "true" ]]; then
        cmd="$cmd --preemptible"
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
    log_info "Machine type: $MACHINE_TYPE"
    [[ "$SPOT" == "true" ]] && log_info "Using Spot VMs"

    local cmd
    cmd=$(build_command)
    run_command "$cmd"

    log_info "Node pool '$NODEPOOL_NAME' created successfully!"
}

main "$@"
