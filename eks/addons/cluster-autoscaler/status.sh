#!/usr/bin/env bash
set -euo pipefail
NS="kube-system"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status cluster-autoscaler -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^cluster-autoscaler$" -o json | jq -r '.[0].chart' | sed 's/cluster-autoscaler-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=aws-cluster-autoscaler --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} cluster-autoscaler v$v - Running ($r pods)"
else echo -e "${RED}❌${NC} cluster-autoscaler - Not installed"; exit 1; fi
