# Quickstart: Addon Development

## Installing an Addon

```bash
# Shared addon
./shared/addons/cert-manager/install.sh --namespace cert-manager

# Platform-specific addon
./eks/addons/aws-load-balancer-controller/install.sh \
    --cluster my-cluster \
    --namespace kube-system
```

## Creating a New Addon

### 1. Determine Classification
- **Shared**: No cloud-specific config → `shared/addons/<name>/`
- **Platform**: Requires IAM/service accounts → `<platform>/addons/<name>/`

### 2. Create Directory Structure
```bash
mkdir -p shared/addons/my-addon
touch shared/addons/my-addon/{install,uninstall,upgrade}.sh
touch shared/addons/my-addon/README.md
chmod +x shared/addons/my-addon/*.sh
```

### 3. Implement Scripts
Use this template for `install.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

# Standard flags
NAMESPACE="my-addon"
RELEASE_NAME="my-addon"
CHART_VERSION=""
DRY_RUN=false

usage() { ... }
parse_args() { ... }
check_dependencies() { ... }
install() { 
    helm upgrade --install "$RELEASE_NAME" repo/chart \
        --namespace "$NAMESPACE" --create-namespace \
        ${CHART_VERSION:+--version "$CHART_VERSION"}
}
main() { ... }
main "$@"
```

### 4. Test Locally
```bash
# Create Kind cluster
kind create cluster --name addon-test

# Test install
./shared/addons/my-addon/install.sh --dry-run

# Test actual install
./shared/addons/my-addon/install.sh

# Test idempotency
./shared/addons/my-addon/install.sh

# Test uninstall
./shared/addons/my-addon/uninstall.sh --force

# Cleanup
kind delete cluster --name addon-test
```

## Common Patterns

### Helm-based Addon
```bash
helm upgrade --install "$RELEASE" "$CHART" \
    --namespace "$NS" --create-namespace \
    --version "$VERSION" \
    --values values.yaml
```

### Manifest-based Addon
```bash
kubectl apply -f https://example.com/manifest.yaml
```

### Cloud API-based Addon (EKS)
```bash
aws eks create-addon \
    --cluster-name "$CLUSTER" \
    --addon-name aws-ebs-csi-driver
```
