#!/usr/bin/env bash
set -euo pipefail
NS="kube-system"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if helm status aws-load-balancer-controller -n "$NS" &>/dev/null; then
    v=$(helm list -n "$NS" -f "^aws-load-balancer-controller$" -o json | jq -r '.[0].chart' | sed 's/aws-load-balancer-controller-//')
    r=$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=aws-load-balancer-controller --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} aws-load-balancer-controller v$v - Running ($r pods)"
else echo -e "${RED}❌${NC} aws-load-balancer-controller - Not installed"; exit 1; fi
