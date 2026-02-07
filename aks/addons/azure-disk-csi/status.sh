#!/usr/bin/env bash
set -euo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if kubectl get csidrivers disk.csi.azure.com &>/dev/null; then
    echo -e "${GREEN}✅${NC} azure-disk-csi - Enabled"
else echo -e "${RED}❌${NC} azure-disk-csi - Not enabled"; exit 1; fi
