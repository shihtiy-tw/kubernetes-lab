# Quick Start: Platform-Aware Wrappers

Learn how to use the unified `k8s.*` wrapper scripts to manage Kubernetes clusters from the repository root.

## Cluster Management

### Create a Cluster
Use `k8s.cluster.create.sh` with the `--platform` flag.

```bash
# Create a local Kind cluster
./scripts/k8s.cluster.create.sh --platform kind --name my-lab

# Create an AWS EKS cluster
./scripts/k8s.cluster.create.sh --platform eks --name my-eks --region us-east-1

# Create a Google GKE cluster
./scripts/k8s.cluster.create.sh --platform gke --name my-gke --project my-project-id
```

### Delete a Cluster
Use `k8s.cluster.delete.sh`.

```bash
# Delete the EKS cluster
./scripts/k8s.cluster.delete.sh --platform eks --name my-eks
```

## Addon Management

### Install an Addon
Use `k8s.addon.install.sh`. The script automatically handles platform-specific Helm values.

```bash
# Install ingress-nginx on AKS
./scripts/k8s.addon.install.sh --platform aks --cluster my-aks --addon ingress-nginx
```

## Global Environment Variables
You can set default values to reduce flag usage:

```bash
export K8S_PLATFORM="eks"
export AWS_REGION="us-west-2"

# Now you can just run:
./scripts/k8s.cluster.create.sh --name auto-default
```

## Dry-Run Mode
All scripts support `--dry-run` to see what command would be executed without making changes.

```bash
./scripts/k8s.cluster.create.sh --platform aks --name test --dry-run
# Output: [DRY RUN] Would execute: ./aks/clusters/create.sh --name test --resource-group test --location eastus
```
