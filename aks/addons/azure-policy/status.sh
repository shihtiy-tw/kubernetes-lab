#!/usr/bin/env bash
set -euo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if kubectl get ns gatekeeper-system &>/dev/null; then
    r=$(kubectl get pods -n gatekeeper-system --no-headers 2>/dev/null | grep -c Running || echo 0)
    echo -e "${GREEN}✅${NC} azure-policy (gatekeeper) - Running ($r pods)"
else echo -e "${RED}❌${NC} azure-policy - Not installed"; exit 1; fi
