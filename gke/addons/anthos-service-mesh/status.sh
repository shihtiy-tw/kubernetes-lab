#!/usr/bin/env bash
set -euo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if kubectl get ns istio-system &>/dev/null; then
    r=$(kubectl get pods -n istio-system --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} anthos-service-mesh - Running ($r pods in istio-system)"
else echo -e "${RED}❌${NC} anthos-service-mesh - Not installed"; exit 1; fi
