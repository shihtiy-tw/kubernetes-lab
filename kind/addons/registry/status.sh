#!/usr/bin/env bash
set -euo pipefail
REGISTRY_NAME="kind-registry"; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
while [[ $# -gt 0 ]]; do case "$1" in --name) REGISTRY_NAME="$2"; shift 2 ;; *) shift ;; esac; done
if docker inspect "$REGISTRY_NAME" &>/dev/null; then
    status=$(docker inspect -f '{{.State.Status}}' "$REGISTRY_NAME")
    echo -e "${GREEN}✅${NC} registry '$REGISTRY_NAME' - $status"
else echo -e "${RED}❌${NC} registry '$REGISTRY_NAME' - Not found"; exit 1; fi
