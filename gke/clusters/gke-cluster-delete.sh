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
FORCE=false
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Delete a GKE cluster.

Required:
    --name NAME             Cluster name
    --region REGION         GCP region (for regional cluster)
                            OR
    --zone ZONE             GCP zone (for zonal cluster)

Optional:
    --project PROJECT       GCP project ID (defaults to gcloud config)
    --force                 Skip confirmation prompt
    --dry-run               Print commands without executing

    --help                  Show this help message
    --version               Show script version

Examples:
    # Delete regional cluster (with confirmation)
    $SCRIPT_NAME --name my-cluster --region us-central1

    # Force delete without confirmation
    $SCRIPT_NAME --name my-cluster --region us-central1 --force

    # Dry run
    $SCRIPT_NAME --name my-cluster --zone us-central1-a --dry-run
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
            --force)
                FORCE=true
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
        log_error "Not authenticated with gcloud. Run: gcloud auth login"
        exit 1
    fi

    if [[ -z "$PROJECT" ]]; then
        PROJECT=$(gcloud config get-value project 2>/dev/null)
        if [[ -z "$PROJECT" ]]; then
            log_error "No project specified and none set in gcloud config"
            exit 1
        fi
        log_info "Using project from gcloud config: $PROJECT"
    fi

    log_info "Dependencies check passed"
}

verify_cluster_exists() {
    log_info "Verifying cluster exists..."
    
    local location_flag=""
    if [[ -n "$REGION" ]]; then
        location_flag="--region $REGION"
    else
        location_flag="--zone $ZONE"
    fi

    if ! gcloud container clusters describe "$CLUSTER_NAME" $location_flag --project "$PROJECT" &> /dev/null; then
        log_error "Cluster '$CLUSTER_NAME' not found"
        exit 1
    fi

    log_info "Cluster '$CLUSTER_NAME' found"
}

confirm_deletion() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    echo ""
    log_warn "You are about to DELETE cluster: $CLUSTER_NAME"
    log_warn "Project: $PROJECT"
    [[ -n "$REGION" ]] && log_warn "Region: $REGION"
    [[ -n "$ZONE" ]] && log_warn "Zone: $ZONE"
    echo ""
    
    read -r -p "Are you sure you want to proceed? Type 'yes' to confirm: " response
    if [[ "$response" != "yes" ]]; then
        log_info "Deletion cancelled"
        exit 0
    fi
}

delete_cluster() {
    local location_flag=""
    if [[ -n "$REGION" ]]; then
        location_flag="--region $REGION"
    else
        location_flag="--zone $ZONE"
    fi

    local cmd="gcloud container clusters delete $CLUSTER_NAME $location_flag --project $PROJECT --quiet"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute:"
        echo "$cmd"
        return 0
    fi

    log_info "Deleting cluster..."
    eval "$cmd"
}

cleanup_kubectl_context() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would clean up kubectl context"
        return 0
    fi

    log_info "Cleaning up kubectl context..."
    
    # Try to remove the context if it exists
    local context_name="gke_${PROJECT}_"
    if [[ -n "$REGION" ]]; then
        context_name="${context_name}${REGION}_${CLUSTER_NAME}"
    else
        context_name="${context_name}${ZONE}_${CLUSTER_NAME}"
    fi

    if kubectl config get-contexts "$context_name" &> /dev/null; then
        kubectl config delete-context "$context_name" 2>/dev/null || true
        log_info "Removed kubectl context: $context_name"
    fi
}

main() {
    parse_args "$@"
    validate_args
    check_dependencies
    verify_cluster_exists
    confirm_deletion
    delete_cluster
    cleanup_kubectl_context

    log_info "GKE cluster '$CLUSTER_NAME' deleted successfully!"
}

main "$@"
