#!/usr/bin/env bash
set -euo pipefail
NS="karpenter"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status karpenter -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^karpenter$" -o json | jq -r '.[0].chart' | sed 's/karpenter-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=karpenter --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} karpenter v$v - Running ($r pods)"
else echo -e "${RED}❌${NC} karpenter - Not installed"; exit 1; fi
