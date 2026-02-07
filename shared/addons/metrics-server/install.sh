#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; NAMESPACE="kube-system"; RELEASE_NAME="metrics-server"; CHART_VERSION=""; DRY_RUN=false
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
usage() { cat << EOF
Usage: $(basename "$0") [OPTIONS]
Install metrics-server for resource metrics.
Options: --namespace NS, --version VER, --dry-run, --help
EOF
}
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
    run_cmd "helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ --force-update"
    run_cmd "helm repo update metrics-server"
    log_info "Installing metrics-server..."
    local cmd="helm upgrade --install $RELEASE_NAME metrics-server/metrics-server -n $NAMESPACE"
    [[ -n "$CHART_VERSION" ]] && cmd="$cmd --version $CHART_VERSION"
    run_cmd "$cmd"
    [[ "$DRY_RUN" != "true" ]] && kubectl wait --for=condition=Available deployment/metrics-server -n "$NAMESPACE" --timeout=120s
    log_info "metrics-server installed!"
}
parse_args "$@"; install
