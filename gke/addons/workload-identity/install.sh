#!/usr/bin/env bash
#
# install.sh - Configure Workload Identity on GKE
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

# Required values
K8S_NAMESPACE=""
K8S_SERVICE_ACCOUNT=""
GCP_SERVICE_ACCOUNT=""
PROJECT=""
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Configure Workload Identity for a Kubernetes service account.

Required:
    --k8s-namespace NS          Kubernetes namespace
    --k8s-sa NAME               Kubernetes service account name
    --gcp-sa EMAIL              GCP service account email

Optional:
    --project PROJECT           GCP project ID (defaults to gcloud config)
    --dry-run                   Print commands without executing

    --help                      Show this help message
    --version                   Show script version

Examples:
    $SCRIPT_NAME --k8s-namespace my-app --k8s-sa my-app-sa --gcp-sa my-app@project.iam.gserviceaccount.com

    $SCRIPT_NAME --k8s-namespace default --k8s-sa app-sa --gcp-sa app@my-project.iam.gserviceaccount.com --dry-run
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --k8s-namespace)
                K8S_NAMESPACE="$2"
                shift 2
                ;;
            --k8s-sa)
                K8S_SERVICE_ACCOUNT="$2"
                shift 2
                ;;
            --gcp-sa)
                GCP_SERVICE_ACCOUNT="$2"
                shift 2
                ;;
            --project)
                PROJECT="$2"
                shift 2
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

    if [[ -z "$K8S_NAMESPACE" ]]; then
        log_error "Kubernetes namespace is required (--k8s-namespace)"
        errors=$((errors + 1))
    fi

    if [[ -z "$K8S_SERVICE_ACCOUNT" ]]; then
        log_error "Kubernetes service account is required (--k8s-sa)"
        errors=$((errors + 1))
    fi

    if [[ -z "$GCP_SERVICE_ACCOUNT" ]]; then
        log_error "GCP service account is required (--gcp-sa)"
        errors=$((errors + 1))
    fi

    if [[ $errors -gt 0 ]]; then
        usage
        exit 1
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud is not installed"
        exit 1
    fi

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
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

run_cmd() {
    local cmd="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] $cmd"
    else
        eval "$cmd"
    fi
}

create_k8s_service_account() {
    log_info "Creating Kubernetes service account..."
    
    # Create namespace if not exists
    run_cmd "kubectl create namespace $K8S_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -"
    
    # Create service account with annotation
    local sa_yaml="apiVersion: v1
kind: ServiceAccount
metadata:
  name: $K8S_SERVICE_ACCOUNT
  namespace: $K8S_NAMESPACE
  annotations:
    iam.gke.io/gcp-service-account: $GCP_SERVICE_ACCOUNT"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would apply:"
        echo "$sa_yaml"
    else
        echo "$sa_yaml" | kubectl apply -f -
    fi
}

bind_iam_policy() {
    log_info "Binding IAM policy..."
    
    local member="serviceAccount:$PROJECT.svc.id.goog[$K8S_NAMESPACE/$K8S_SERVICE_ACCOUNT]"
    
    run_cmd "gcloud iam service-accounts add-iam-policy-binding $GCP_SERVICE_ACCOUNT \
        --role=roles/iam.workloadIdentityUser \
        --member=\"$member\" \
        --project=$PROJECT"
}

main() {
    parse_args "$@"
    validate_args
    check_dependencies

    log_info "Configuring Workload Identity..."
    log_info "K8s Namespace: $K8S_NAMESPACE"
    log_info "K8s Service Account: $K8S_SERVICE_ACCOUNT"
    log_info "GCP Service Account: $GCP_SERVICE_ACCOUNT"

    create_k8s_service_account
    bind_iam_policy

    log_info "Workload Identity configured successfully!"
    log_info "Pods using service account '$K8S_SERVICE_ACCOUNT' in namespace '$K8S_NAMESPACE' can now access GCP resources as '$GCP_SERVICE_ACCOUNT'"
}

main "$@"
