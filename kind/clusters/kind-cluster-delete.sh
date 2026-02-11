#!/bin/bash
set -euo pipefail
echo "Deleting kind cluster..."
kind delete cluster "$@"
