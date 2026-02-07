#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="cert-manager"
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

if helm status cert-manager -n "$NAMESPACE" &>/dev/null; then
    version=$(helm list -n "$NAMESPACE" -f "^cert-manager$" -o json | jq -r '.[0].chart' | sed 's/cert-manager-//')
    ready=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance=cert-manager -o jsonpath='{.items[*].status.phase}' | tr ' ' '\n' | grep -c Running || echo 0)
    total=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance=cert-manager --no-headers | wc -l)
    echo -e "${GREEN}✅${NC} cert-manager v$version - Running ($ready/$total pods ready)"
else
    echo -e "${RED}❌${NC} cert-manager - Not installed"
    exit 1
fi
