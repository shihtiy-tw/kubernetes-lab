#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; PROJECT=""; NAMESPACE="cnrm-system"; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
usage() { echo "Usage: $(basename "$0") --project PROJECT [--namespace NS] [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --project) PROJECT="$2"; shift 2 ;; --namespace) NAMESPACE="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; *) shift ;; esac; done
[[ -z "$PROJECT" ]] && { echo "Project required"; exit 1; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Enabling Config Connector API..."
run_cmd "gcloud services enable cloudresourcemanager.googleapis.com serviceusage.googleapis.com --project=$PROJECT"
log_info "Installing Config Connector operator..."
run_cmd "gcloud components install config-connector --quiet" || true
log_info "Adding Helm repo..."
run_cmd "helm repo add configconnector https://gke-config-connector.storage.googleapis.com/charts --force-update" || true
log_info "Installing Config Connector..."
cmd="kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-config-connector/master/install-bundles/install-bundle-workload-identity/install-bundle.yaml"
run_cmd "$cmd"
log_info "Config Connector installed! Create ConfigConnector and ConfigConnectorContext resources to configure."
