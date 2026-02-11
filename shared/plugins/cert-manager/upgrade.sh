#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

NAMESPACE="cert-manager"
RELEASE_NAME="cert-manager"
TO_VERSION=""
VALUES_FILE=""
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]
Upgrade cert-manager.
Options:
    --namespace NS      Namespace (default: cert-manager)
    --release-name NAME Release name (default: cert-manager)
    --to-version VER    Target version
    --values FILE       Custom values file
    --dry-run           Print without executing
    --help              Show help
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --namespace) NAMESPACE="$2"; shift 2 ;;
            --release-name) RELEASE_NAME="$2"; shift 2 ;;
            --to-version) TO_VERSION="$2"; shift 2 ;;
            --values) VALUES_FILE="$2"; shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) usage; exit 0 ;;
            *) log_error "Unknown: $1"; exit 1 ;;
        esac
    done
}

run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }

upgrade() {
    if ! helm status "$RELEASE_NAME" -n "$NAMESPACE" &>/dev/null; then
        log_error "cert-manager not installed. Use install.sh first."
        exit 1
    fi

    log_info "Upgrading cert-manager..."
    run_cmd "helm repo update jetstack"
    
    local cmd="helm upgrade $RELEASE_NAME jetstack/cert-manager -n $NAMESPACE"
    [[ -n "$TO_VERSION" ]] && cmd="$cmd --version $TO_VERSION"
    [[ -n "$VALUES_FILE" ]] && cmd="$cmd --values $VALUES_FILE"
    
    run_cmd "$cmd"
    log_info "cert-manager upgraded!"
}

main() { parse_args "$@"; upgrade; }
main "$@"
