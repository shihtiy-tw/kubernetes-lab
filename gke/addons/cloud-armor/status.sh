#!/usr/bin/env bash
set -euo pipefail
PROJECT=""; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
while [[ $# -gt 0 ]]; do case "$1" in --project) PROJECT="$2"; shift 2 ;; *) shift ;; esac; done
[[ -z "$PROJECT" ]] && { echo "Usage: $(basename "$0") --project PROJECT"; exit 1; }
count=$(gcloud compute security-policies list --project="$PROJECT" --format="value(name)" | wc -l)
if [[ $count -gt 0 ]]; then echo -e "${GREEN}✅${NC} cloud-armor - $count policies configured"
else echo -e "${RED}❌${NC} cloud-armor - No policies"; exit 1; fi
