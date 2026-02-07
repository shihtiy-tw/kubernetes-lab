#!/usr/bin/env bash
set -euo pipefail
NS="monitoring"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status prometheus-stack -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^prometheus-stack$" -o json | jq -r '.[0].chart' | sed 's/kube-prometheus-stack-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=prometheus-stack --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} prometheus-stack v$v - Running ($r pods)"
else echo -e "${RED}❌${NC} prometheus-stack - Not installed"; exit 1; fi
