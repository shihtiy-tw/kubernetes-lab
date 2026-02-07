#!/usr/bin/env bash
set -euo pipefail
NS="external-dns"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status external-dns -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^external-dns$" -o json | jq -r '.[0].chart' | sed 's/external-dns-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=external-dns --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} external-dns v$v - Running ($r pods)"
else echo -e "${RED}❌${NC} external-dns - Not installed"; exit 1; fi
