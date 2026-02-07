---
description: Delete Kubernetes cluster with platform awareness
---

# k8s.cluster.delete

## Purpose

Delete a Kubernetes cluster on the specified platform with safety checks.

## Platform Support

**Supported Platforms**: `kind`, `eks`, `gke`, `aks`

## Usage

```bash
# Delete kind cluster
./scripts/k8s.cluster.delete.sh --platform kind --name dev-local

# Delete EKS cluster
./scripts/k8s.cluster.delete.sh --platform eks --name prod-cluster --region us-west-2

# Delete GKE cluster
./scripts/k8s.cluster.delete.sh --platform gke --name staging-cluster --project my-project --region us-central1

# Delete AKS cluster
./scripts/k8s.cluster.delete.sh --platform aks --name test-cluster --resource-group my-rg

# Force delete (skip confirmation)
./scripts/k8s.cluster.delete.sh --platform kind --name dev-local --force
```

## Parameters

- `--platform` (required) - Target platform: `kind` | `eks` | `gke` | `aks`
- `--name` (required) - Cluster name to delete
- `--force` (optional) - Skip confirmation prompt
- Platform-specific parameters (same as create)

## Prerequisites

- Platform CLI tools installed
- Cluster exists
- Appropriate permissions

## Steps

1. Validate platform and cluster name
2. Check cluster exists
3. List resources in cluster (warning)
4. Confirm deletion (unless --force)
5. Delete cluster
6. Clean up kubeconfig entries
7. Confirm deletion complete

## Platform-Specific Behavior

### kind
```bash
kind delete cluster --name dev-local
```

### EKS
```bash
eksctl delete cluster --name prod-cluster --region us-west-2
```

### GKE
```bash
gcloud container clusters delete staging-cluster --project my-project --region us-central1 --quiet
```

### AKS
```bash
az aks delete --name test-cluster --resource-group my-rg --yes
```

## Safety Checks

- [ ] Validate cluster exists
- [ ] Show running workloads warning
- [ ] Require confirmation for cloud clusters
- [ ] For `prod` in name: Double confirmation required
- [ ] Clean up local kubeconfig

## Related

- [k8s.cluster.create](./k8s.cluster.create.md) - Create cluster
