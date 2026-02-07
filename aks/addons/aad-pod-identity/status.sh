#!/usr/bin/env bash
set -euo pipefail
NS="kube-system"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status aad-pod-identity -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^aad-pod-identity$" -o json | jq -r '.[0].chart' | sed 's/aad-pod-identity-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=aad-pod-identity --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} aad-pod-identity v$v - Running ($r pods)"
else echo -e "${RED}❌${NC} aad-pod-identity - Not installed"; exit 1; fi
