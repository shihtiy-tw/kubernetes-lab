#!/bin/bash
set -euo pipefail
echo "Creating kind cluster..."
./kind/clusters/basic/create.sh "$@"
