#!/usr/bin/env bash
set -euo pipefail
NS="argocd"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status argocd -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^argocd$" -o json | jq -r '.[0].chart' | sed 's/argo-cd-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=argocd --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} argocd v$v - Running ($r pods)"
else echo -e "${RED}❌${NC} argocd - Not installed"; exit 1; fi
