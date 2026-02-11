#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

NAMESPACE="external-dns"
RELEASE_NAME="external-dns"
DRY_RUN=false
DOMAIN_FILTER=""
GCP_PROJECT=""

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Install ExternalDNS configured for Google Cloud DNS.

Optional:
    --namespace NS          Kubernetes namespace (default: external-dns)
    --domain DOMAIN         Domain filter (e.g., example.com)
    --project PROJECT       GCP Project ID for Cloud DNS
    --dry-run               Print commands without executing

    --help                  Show this help message
    --version               Show script version
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --namespace) NAMESPACE="$2"; shift 2 ;;
            --domain) DOMAIN_FILTER="$2"; shift 2 ;;
            --project) GCP_PROJECT="$2"; shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) usage; exit 0 ;;
            --version) echo "$VERSION"; exit 0 ;;
            *) log_error "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
}

check_dependencies() {
    log_info "Checking dependencies..."
    for cmd in helm kubectl gcloud; do
        if ! command -v $cmd &> /dev/null; then
            log_error "$cmd is not installed"
            exit 1
        fi
    done
    
    if [[ -z "$GCP_PROJECT" ]]; then
        GCP_PROJECT=$(gcloud config get-value project 2>/dev/null)
    fi
}

install() {
    log_info "Installing ExternalDNS for Cloud DNS..."
    
    local cmd="helm upgrade --install $RELEASE_NAME external-dns/external-dns"
    cmd="$cmd --namespace $NAMESPACE --create-namespace"
    cmd="$cmd --set provider=google"
    cmd="$cmd --set google.project=$GCP_PROJECT"
    
    if [[ -n "$DOMAIN_FILTER" ]]; then
        cmd="$cmd --set domainFilters={$DOMAIN_FILTER}"
    fi
    
    # Policy for GKE
    cmd="$cmd --set policy=sync"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] $cmd"
    else
        helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ || true
        helm repo update
        eval "$cmd"
    fi
}

main() {
    parse_args "$@"
    check_dependencies
    install
    log_info "Cloud DNS (ExternalDNS) installed successfully!"
}

main "$@"
