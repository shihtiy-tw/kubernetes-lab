#!/usr/bin/env bash
set -euo pipefail
NS="${1:-default}"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if kubectl get configmap cloud-sql-proxy-config -n "$NS" &>/dev/null; then
    echo -e "${GREEN}✅${NC} cloud-sql-proxy config exists in $NS"
else echo -e "${RED}❌${NC} cloud-sql-proxy config not found in $NS"; exit 1; fi
