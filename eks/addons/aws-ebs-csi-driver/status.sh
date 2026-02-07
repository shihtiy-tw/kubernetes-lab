#!/usr/bin/env bash
set -euo pipefail
CLUSTER_NAME=""; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
while [[ $# -gt 0 ]]; do case "$1" in --cluster) CLUSTER_NAME="$2"; shift 2 ;; *) shift ;; esac; done
[[ -z "$CLUSTER_NAME" ]] && { echo "Usage: $(basename "$0") --cluster NAME"; exit 1; }
status=$(aws eks describe-addon --cluster-name "$CLUSTER_NAME" --addon-name aws-ebs-csi-driver --query 'addon.status' --output text 2>/dev/null || echo "NOT_FOUND")
if [[ "$status" == "ACTIVE" ]]; then
    v=$(aws eks describe-addon --cluster-name "$CLUSTER_NAME" --addon-name aws-ebs-csi-driver --query 'addon.addonVersion' --output text)
    echo -e "${GREEN}✅${NC} aws-ebs-csi-driver $v - $status"
else echo -e "${RED}❌${NC} aws-ebs-csi-driver - $status"; exit 1; fi
