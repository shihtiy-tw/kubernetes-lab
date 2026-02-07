#!/usr/bin/env bash
set -euo pipefail
NS="kube-system"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status metrics-server -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^metrics-server$" -o json | jq -r '.[0].chart' | sed 's/metrics-server-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=metrics-server -o jsonpath='{.items[*].status.phase}' | tr ' ' '\n' | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} metrics-server v$v - Running ($r pods)"
else
    echo -e "${RED}❌${NC} metrics-server - Not installed"; exit 1
fi
