#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; NAMESPACE="ingress-nginx"; RELEASE_NAME="ingress-nginx"; CHART_VERSION=""; DRY_RUN=false
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
usage() { echo "Usage: $(basename "$0") [--namespace NS] [--version VER] [--dry-run] [--help]"; }
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --namespace) NAMESPACE="$2"; shift 2 ;; --version) CHART_VERSION="$2"; shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;;
            --script-version) echo "v$VERSION"; exit 0 ;; *) log_error "Unknown: $1"; exit 1 ;;
        esac
    done
}
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
install() {
    log_info "Adding Helm repo..."
    run_cmd "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update"
    run_cmd "helm repo update ingress-nginx"
    log_info "Installing ingress-nginx..."
    local cmd="helm upgrade --install $RELEASE_NAME ingress-nginx/ingress-nginx -n $NAMESPACE --create-namespace"
    [[ -n "$CHART_VERSION" ]] && cmd="$cmd --version $CHART_VERSION"
    run_cmd "$cmd"
    [[ "$DRY_RUN" != "true" ]] && kubectl wait --for=condition=Available deployment/$RELEASE_NAME-controller -n "$NAMESPACE" --timeout=180s
    log_info "ingress-nginx installed!"
}
parse_args "$@"; install
