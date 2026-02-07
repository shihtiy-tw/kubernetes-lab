#!/usr/bin/env bash
set -euo pipefail
NS="kube-system"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status secrets-store-csi-driver -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^secrets-store-csi-driver$" -o json | jq -r '.[0].chart' | sed 's/secrets-store-csi-driver-//')
    r=$(kubectl get pods -n "$NS" -l app=secrets-store-csi-driver --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} secrets-store-csi-driver v$v - Running ($r pods)"
else echo -e "${RED}❌${NC} secrets-store-csi-driver - Not installed"; exit 1; fi
