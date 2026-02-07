#!/usr/bin/env bash
set -euo pipefail
NS="default"; DRY_RUN=false
while [[ $# -gt 0 ]]; do case "$1" in --namespace) NS="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--namespace NS] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
run_cmd "kubectl delete configmap cloud-sql-proxy-config -n $NS --ignore-not-found"
echo "Cloud SQL Proxy config removed from namespace $NS"
