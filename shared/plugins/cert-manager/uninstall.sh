#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

NAMESPACE="cert-manager"
RELEASE_NAME="cert-manager"
DELETE_CRDS=false
FORCE=false
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]
Uninstall cert-manager.
Options:
    --namespace NS      Namespace (default: cert-manager)
    --release-name NAME Release name (default: cert-manager)
    --delete-crds       Also delete CRDs
    --force             Skip confirmation
    --dry-run           Print without executing
    --help              Show help
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --namespace) NAMESPACE="$2"; shift 2 ;;
            --release-name) RELEASE_NAME="$2"; shift 2 ;;
            --delete-crds) DELETE_CRDS=true; shift ;;
            --force) FORCE=true; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) usage; exit 0 ;;
            *) log_error "Unknown: $1"; exit 1 ;;
        esac
    done
}

run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }

uninstall() {
    if [[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]]; then
        read -rp "Uninstall cert-manager? (yes/no): " confirm
        [[ "$confirm" != "yes" ]] && { log_info "Cancelled"; exit 0; }
    fi

    log_info "Uninstalling cert-manager..."
    run_cmd "helm uninstall $RELEASE_NAME -n $NAMESPACE" || true

    if [[ "$DELETE_CRDS" == "true" ]]; then
        log_info "Deleting CRDs..."
        run_cmd "kubectl delete crd certificates.cert-manager.io certificaterequests.cert-manager.io challenges.acme.cert-manager.io clusterissuers.cert-manager.io issuers.cert-manager.io orders.acme.cert-manager.io" || true
    fi

    run_cmd "kubectl delete namespace $NAMESPACE --ignore-not-found"
    log_info "cert-manager uninstalled!"
}

main() { parse_args "$@"; uninstall; }
main "$@"
