#!/usr/bin/env bash
set -euo pipefail
NS="external-secrets"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status external-secrets -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^external-secrets$" -o json | jq -r '.[0].chart' | sed 's/external-secrets-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=external-secrets --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} external-secrets v$v - Running ($r pods)"
else echo -e "${RED}❌${NC} external-secrets - Not installed"; exit 1; fi
