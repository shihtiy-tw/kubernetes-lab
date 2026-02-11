#!/usr/bin/env bash
#
# install.sh - Install cert-manager
# Part of kubernetes-lab (Spec 003: Addon Standards)
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

# Default values
NAMESPACE="cert-manager"
RELEASE_NAME="cert-manager"
CHART_VERSION=""
VALUES_FILE=""
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Install cert-manager for automated TLS certificate management.

Options:
    --namespace NS          Kubernetes namespace (default: cert-manager)
    --release-name NAME     Helm release name (default: cert-manager)
    --version VER           Chart version (default: latest)
    --values FILE           Custom values file
    --dry-run               Print commands without executing
    --help                  Show this help message
    --script-version        Show script version

Examples:
    $SCRIPT_NAME
    $SCRIPT_NAME --version 1.14.0
    $SCRIPT_NAME --values custom-values.yaml
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --namespace) NAMESPACE="$2"; shift 2 ;;
            --release-name) RELEASE_NAME="$2"; shift 2 ;;
            --version) CHART_VERSION="$2"; shift 2 ;;
            --values) VALUES_FILE="$2"; shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) usage; exit 0 ;;
            --script-version) echo "$SCRIPT_NAME version $VERSION"; exit 0 ;;
            *) log_error "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
}

check_dependencies() {
    log_info "Checking dependencies..."
    command -v helm &>/dev/null || { log_error "helm not found"; exit 2; }
    command -v kubectl &>/dev/null || { log_error "kubectl not found"; exit 2; }
    kubectl cluster-info &>/dev/null || { log_error "Cannot connect to cluster"; exit 2; }
    log_info "Dependencies OK"
}

run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

install() {
    log_info "Adding Helm repository..."
    run_cmd "helm repo add jetstack https://charts.jetstack.io --force-update"
    run_cmd "helm repo update jetstack"

    log_info "Installing cert-manager..."
    local cmd="helm upgrade --install $RELEASE_NAME jetstack/cert-manager"
    cmd="$cmd --namespace $NAMESPACE --create-namespace"
    cmd="$cmd --set installCRDs=true"
    [[ -n "$CHART_VERSION" ]] && cmd="$cmd --version $CHART_VERSION"
    [[ -n "$VALUES_FILE" ]] && cmd="$cmd --values $VALUES_FILE"

    run_cmd "$cmd"

    if [[ "$DRY_RUN" != "true" ]]; then
        log_info "Waiting for cert-manager to be ready..."
        kubectl wait --for=condition=Available deployment/cert-manager -n "$NAMESPACE" --timeout=120s
        kubectl wait --for=condition=Available deployment/cert-manager-webhook -n "$NAMESPACE" --timeout=120s
        kubectl wait --for=condition=Available deployment/cert-manager-cainjector -n "$NAMESPACE" --timeout=120s
    fi

    log_info "cert-manager installed successfully!"
}

main() {
    parse_args "$@"
    check_dependencies
    install
}

main "$@"
