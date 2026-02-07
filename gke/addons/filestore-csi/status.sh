#!/usr/bin/env bash
set -euo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if kubectl get csidrivers filestore.csi.storage.gke.io &>/dev/null; then
    echo -e "${GREEN}✅${NC} filestore-csi - Enabled"
else echo -e "${RED}❌${NC} filestore-csi - Not enabled"; exit 1; fi
