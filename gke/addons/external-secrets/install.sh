#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

NAMESPACE="external-secrets"
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Install External Secrets Operator on GKE.

Optional:
    --namespace NS          Kubernetes namespace (default: external-secrets)
    --dry-run               Print commands without executing
    --help                  Show this help message
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --namespace) NAMESPACE="$2"; shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) usage; exit 0 ;;
            *) log_error "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
}

install() {
    log_info "Installing External Secrets Operator..."
    
    local cmd="helm upgrade --install external-secrets external-secrets/external-secrets"
    cmd="$cmd --namespace $NAMESPACE --create-namespace"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] $cmd"
    else
        helm repo add external-secrets https://charts.external-secrets.io || true
        helm repo update
        eval "$cmd"
    fi
}

main() {
    parse_args "$@"
    install
    log_info "External Secrets Operator installed successfully!"
}

main "$@"
