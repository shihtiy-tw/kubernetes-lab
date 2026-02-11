#!/usr/bin/env bash
set -euo pipefail

VERSION="1.1.0"
SCRIPT_NAME="$(basename "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

CLUSTER_NAME=""
REGION=""
ZONE=""
PROJECT=""
NODE_COUNT=2
MACHINE_TYPE="e2-medium"
DISK_SIZE=100
K8S_VERSION="latest"
NETWORK=""
SUBNETWORK=""
RELEASE_CHANNEL="regular"
ENABLE_PRIVATE=""
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Create a GKE cluster with standard configuration.

Required:
    --name NAME             Cluster name
    --region REGION         GCP region (e.g., us-central1)
                            OR
    --zone ZONE             GCP zone (e.g., us-central1-a) for zonal cluster

Optional:
    --project PROJECT       GCP project ID (defaults to gcloud config)
    --node-count N          Initial node count per zone (default: 2)
    --machine-type TYPE     Machine type (default: e2-medium)
    --disk-size GB          Boot disk size in GB (default: 100)
    --k8s-version VERSION   Kubernetes version (default: latest)
    --network NAME          VPC network name
    --subnetwork NAME       Subnetwork name
    --release-channel CH    Release channel: rapid, regular, stable (default: regular)
    --private               Enable private cluster
    --dry-run               Print commands without executing

    --help                  Show this help message
    --version               Show script version

Examples:
    # Create regional cluster
    $SCRIPT_NAME --name my-cluster --region us-central1

    # Create zonal cluster with custom settings
    $SCRIPT_NAME --name dev-cluster --zone us-central1-a --node-count 3 --machine-type e2-standard-2

    # Dry run to preview commands
    $SCRIPT_NAME --name my-cluster --region us-central1 --dry-run
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)
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
            --machine-type)
                MACHINE_TYPE="$2"
                shift 2
                ;;
            --disk-size)
                DISK_SIZE="$2"
                shift 2
                ;;
            --k8s-version)
                K8S_VERSION="$2"
                shift 2
                ;;
            --network)
                NETWORK="$2"
                shift 2
                ;;
            --subnetwork)
                SUBNETWORK="$2"
                shift 2
                ;;
            --release-channel)
                RELEASE_CHANNEL="$2"
                shift 2
                ;;
            --private)
                ENABLE_PRIVATE="--enable-private-nodes --enable-private-endpoint"
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

    if [[ -z "$REGION" && -z "$ZONE" ]]; then
        log_error "Either --region or --zone is required"
        errors=$((errors + 1))
    fi

    if [[ -n "$REGION" && -n "$ZONE" ]]; then
        log_error "Cannot specify both --region and --zone"
        errors=$((errors + 1))
    fi

    # Check for gcloud CLI
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed. See: https://cloud.google.com/sdk/docs/install"
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

    # Check gcloud authentication
    if ! gcloud auth print-access-token &> /dev/null; then
        log_error "Not authenticated with gcloud. Run: gcloud auth login"
        exit 1
    fi

    # Get project if not specified
    if [[ -z "$PROJECT" ]]; then
        PROJECT=$(gcloud config get-value project 2>/dev/null)
        if [[ -z "$PROJECT" ]]; then
            log_error "No project specified and none set in gcloud config"
            exit 1
        fi
        log_info "Using project from gcloud config: $PROJECT"
    fi

    # Verify project exists and we have access
    if ! gcloud projects describe "$PROJECT" &> /dev/null; then
        log_error "Cannot access project: $PROJECT"
        exit 1
    fi

    log_info "Dependencies check passed"
}

build_command() {
    local cmd="gcloud container clusters create $CLUSTER_NAME"
    
    # Location
    if [[ -n "$REGION" ]]; then
        cmd="$cmd --region $REGION"
    else
        cmd="$cmd --zone $ZONE"
    fi

    # Project
    cmd="$cmd --project $PROJECT"

    # Node configuration
    cmd="$cmd --num-nodes $NODE_COUNT"
    cmd="$cmd --machine-type $MACHINE_TYPE"
    cmd="$cmd --disk-size $DISK_SIZE"

    # Kubernetes version / release channel
    if [[ "$K8S_VERSION" != "latest" ]]; then
        cmd="$cmd --cluster-version $K8S_VERSION"
    fi
    cmd="$cmd --release-channel $RELEASE_CHANNEL"

    # Network
    if [[ -n "$NETWORK" ]]; then
        cmd="$cmd --network $NETWORK"
    fi
    if [[ -n "$SUBNETWORK" ]]; then
        cmd="$cmd --subnetwork $SUBNETWORK"
    fi

    # Private cluster
    if [[ -n "$ENABLE_PRIVATE" ]]; then
        cmd="$cmd $ENABLE_PRIVATE"
    fi

    # Standard settings
    cmd="$cmd --enable-ip-alias"
    cmd="$cmd --enable-autorepair"
    cmd="$cmd --enable-autoupgrade"

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
    
    local location_flag=""
    if [[ -n "$REGION" ]]; then
        location_flag="--region $REGION"
    else
        location_flag="--zone $ZONE"
    fi

    gcloud container clusters get-credentials "$CLUSTER_NAME" $location_flag --project "$PROJECT"
    
    log_info "kubectl configured. Current context:"
    kubectl config current-context
}

main() {
    parse_args "$@"
    validate_args
    check_dependencies

    log_info "Creating GKE cluster: $CLUSTER_NAME"
    log_info "Project: $PROJECT"
    [[ -n "$REGION" ]] && log_info "Region: $REGION"
    [[ -n "$ZONE" ]] && log_info "Zone: $ZONE"
    log_info "Node count: $NODE_COUNT"
    log_info "Machine type: $MACHINE_TYPE"

    local cmd
    cmd=$(build_command)
    run_command "$cmd"

    configure_kubectl

    log_info "GKE cluster '$CLUSTER_NAME' created successfully!"
}

main "$@"
