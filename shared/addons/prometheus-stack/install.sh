#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; NAMESPACE="monitoring"; RELEASE_NAME="prometheus-stack"; CHART_VERSION=""; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
usage() { echo "Usage: $(basename "$0") [--namespace NS] [--version VER] [--dry-run] [--help]"; }
while [[ $# -gt 0 ]]; do case "$1" in --namespace) NAMESPACE="$2"; shift 2 ;; --version) CHART_VERSION="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; --script-version) echo "v$VERSION"; exit 0 ;; *) shift ;; esac; done
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Adding Helm repo..."
run_cmd "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update"
run_cmd "helm repo update prometheus-community"
log_info "Installing prometheus-stack..."
cmd="helm upgrade --install $RELEASE_NAME prometheus-community/kube-prometheus-stack -n $NAMESPACE --create-namespace"
[[ -n "$CHART_VERSION" ]] && cmd="$cmd --version $CHART_VERSION"
run_cmd "$cmd"
log_info "prometheus-stack installed! Access Grafana: kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n $NAMESPACE"
