#!/usr/bin/env bash
set -euo pipefail
NS="ingress-nginx"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status ingress-nginx -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^ingress-nginx$" -o json | jq -r '.[0].chart' | sed 's/ingress-nginx-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[*].status.phase}' | tr ' ' '\n' | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} ingress-nginx v$v - Running ($r pods)"
else
    echo -e "${RED}❌${NC} ingress-nginx - Not installed"; exit 1
fi
