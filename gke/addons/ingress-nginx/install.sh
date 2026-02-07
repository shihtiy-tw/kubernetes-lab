#!/usr/bin/env bash
#
# install.sh - Install Ingress NGINX on GKE
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

# Default values
NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"
CHART_VERSION=""
DRY_RUN=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Install Ingress NGINX controller on GKE.

Optional:
    --namespace NS          Kubernetes namespace (default: ingress-nginx)
    --release-name NAME     Helm release name (default: ingress-nginx)
    --chart-version VER     Specific chart version
    --dry-run               Print commands without executing

    --help                  Show this help message
    --version               Show script version

Examples:
    $SCRIPT_NAME
    $SCRIPT_NAME --namespace custom-ingress
    $SCRIPT_NAME --dry-run
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            --release-name)
                RELEASE_NAME="$2"
                shift 2
                ;;
            --chart-version)
                CHART_VERSION="$2"
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

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed"
        exit 1
    fi

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi

    # Verify kubectl context
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    log_info "Dependencies check passed"
}

install_ingress_nginx() {
    log_info "Adding ingress-nginx Helm repository..."
    
    local cmd="helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] $cmd"
    else
        eval "$cmd" || true
        helm repo update
    fi

    log_info "Installing Ingress NGINX..."

    cmd="helm upgrade --install $RELEASE_NAME ingress-nginx/ingress-nginx"
    cmd="$cmd --namespace $NAMESPACE --create-namespace"
    
    # GKE-specific values
    cmd="$cmd --set controller.service.type=LoadBalancer"
    cmd="$cmd --set controller.service.externalTrafficPolicy=Local"
    
    if [[ -n "$CHART_VERSION" ]]; then
        cmd="$cmd --version $CHART_VERSION"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] $cmd"
        return 0
    fi

    eval "$cmd"
}

wait_for_ready() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would wait for pods to be ready"
        return 0
    fi

    log_info "Waiting for Ingress NGINX pods to be ready..."
    kubectl wait --namespace "$NAMESPACE" \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=120s

    log_info "Getting LoadBalancer IP..."
    kubectl get svc -n "$NAMESPACE" "$RELEASE_NAME-controller" -o wide
}

main() {
    parse_args "$@"
    check_dependencies
    install_ingress_nginx
    wait_for_ready

    log_info "Ingress NGINX installed successfully!"
}

main "$@"
