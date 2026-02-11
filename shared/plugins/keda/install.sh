#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; NAMESPACE="keda"; RELEASE_NAME="keda"; CHART_VERSION=""; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
usage() { echo "Usage: $(basename "$0") [--namespace NS] [--version VER] [--dry-run] [--help]"; }
while [[ $# -gt 0 ]]; do case "$1" in --namespace) NAMESPACE="$2"; shift 2 ;; --version) CHART_VERSION="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; --script-version) echo "v$VERSION"; exit 0 ;; *) shift ;; esac; done
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Adding Helm repo..."
run_cmd "helm repo add kedacore https://kedacore.github.io/charts --force-update"
run_cmd "helm repo update kedacore"
log_info "Installing KEDA..."
cmd="helm upgrade --install $RELEASE_NAME kedacore/keda -n $NAMESPACE --create-namespace"
[[ -n "$CHART_VERSION" ]] && cmd="$cmd --version $CHART_VERSION"
run_cmd "$cmd"
log_info "KEDA installed! Create ScaledObject resources to enable event-driven autoscaling."
