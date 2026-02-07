#!/usr/bin/env bash
set -euo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if kubectl get csidrivers file.csi.azure.com &>/dev/null; then
    echo -e "${GREEN}✅${NC} azure-file-csi - Enabled"
else echo -e "${RED}❌${NC} azure-file-csi - Not enabled"; exit 1; fi
