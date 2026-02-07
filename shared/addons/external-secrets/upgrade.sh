#!/usr/bin/env bash
set -euo pipefail
NS="external-secrets"; RN="external-secrets"; TO_VERSION=""; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --to-version) TO_VERSION="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--to-version VER] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
helm status "$RN" -n "$NS" &>/dev/null || { echo "Not installed"; exit 1; }
run_cmd "helm repo update external-secrets"
cmd="helm upgrade $RN external-secrets/external-secrets -n $NS"
[[ -n "$TO_VERSION" ]] && cmd="$cmd --version $TO_VERSION"
run_cmd "$cmd"
echo "external-secrets upgraded!"
