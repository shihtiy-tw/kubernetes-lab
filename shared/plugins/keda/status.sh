#!/usr/bin/env bash
set -euo pipefail
NS="keda"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status keda -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^keda$" -o json | jq -r '.[0].chart' | sed 's/keda-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=keda --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} keda v$v - Running ($r pods)"
else echo -e "${RED}❌${NC} keda - Not installed"; exit 1; fi
