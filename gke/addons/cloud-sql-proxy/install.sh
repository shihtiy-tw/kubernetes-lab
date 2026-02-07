#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; NAMESPACE="default"; INSTANCE=""; PROJECT=""; REGION=""; SA_NAME=""; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
usage() { cat << EOF
Usage: $(basename "$0") --namespace NS --instance PROJECT:REGION:INSTANCE [--sa-name SA] [--dry-run]
Example: --instance my-project:us-central1:my-db
EOF
}
while [[ $# -gt 0 ]]; do case "$1" in --namespace) NAMESPACE="$2"; shift 2 ;; --instance) INSTANCE="$2"; shift 2 ;; --sa-name) SA_NAME="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; *) shift ;; esac; done
[[ -z "$INSTANCE" ]] && { echo "Instance connection string required"; usage; exit 1; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Installing Cloud SQL Proxy as sidecar pattern..."
cat << 'YAML' | kubectl apply -n "$NAMESPACE" -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloud-sql-proxy-config
data:
  INSTANCES: "${INSTANCE}"
YAML
log_info "Cloud SQL Proxy config created in namespace $NAMESPACE"
log_info "Add gcr.io/cloud-sql-connectors/cloud-sql-proxy:2 as a sidecar to your deployment"
