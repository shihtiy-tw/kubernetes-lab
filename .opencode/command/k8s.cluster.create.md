---
description: Create Kubernetes cluster with platform awareness (kind, EKS, GKE, AKS)
---

# k8s.cluster.create

## Purpose

Create a Kubernetes cluster on the specified platform with standardized configuration.

## Platform Support

**Supported Platforms**: `kind`, `eks`, `gke`, `aks`

## Usage

```bash
# Local development with kind
./scripts/k8s.cluster.create.sh --platform kind --name dev-local

# AWS EKS production cluster
./scripts/k8s.cluster.create.sh --platform eks \
  --name prod-cluster \
  --region us-west-2 \
  --node-type m5.large \
  --nodes 3

# GCP GKE staging cluster
./scripts/k8s.cluster.create.sh --platform gke \
  --name staging-cluster \
  --project my-gcp-project \
  --region us-central1 \
  --machine-type n1-standard-2 \
  --num-nodes 2

# Azure AKS test cluster
./scripts/k8s.cluster.create.sh --platform aks \
  --name test-cluster \
  --resource-group my-resource-group \
  --location eastus \
  --node-count 2
```

## Parameters

- `--platform` (required) - Target platform: `kind` | `eks` | `gke` | `aks`
- `--name` (required) - Cluster name
- Platform-specific:
  - **kind**: `--config` (kind config file)
  - **eks**: `--region`, `--node-type`, `--nodes`, `--version`
  - **gke**: `--project`, `--region`, `--machine-type`, `--num-nodes`
  - **aks**: `--resource-group`, `--location`, `--node-count`, `--node-vm-size`

## Prerequisites

- Platform CLI tools installed:
  - kind: `kind`
  - eks: `eksctl`, `aws`
  - gke: `gcloud`
  - aks: `az`
- Credentials configured for cloud platforms

## Steps

1. Validate platform and parameters
2. Check CLI tools installed
3. Verify credentials (cloud platforms)
4. Create cluster with platform-specific command
5. Update kubeconfig
6. Verify cluster health
7. Output cluster information

## Platform-Specific Behavior

### kind (Local)
```bash
kind create cluster --name dev-local --config kind-config.yaml
# Kubeconfig automatically updated
```

### EKS (AWS)
```bash
eksctl create cluster \
  --name prod-cluster \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type m5.large \
  --nodes 3

aws eks update-kubeconfig --name prod-cluster --region us-west-2
```

### GKE (GCP)
```bash
gcloud container clusters create staging-cluster \
  --project my-project \
  --region us-central1 \
  --machine-type n1-standard-2 \
  --num-nodes 2

gcloud container clusters get-credentials staging-cluster --region us-central1
```

### AKS (Azure)
```bash
az aks create \
  --name test-cluster \
  --resource-group my-rg \
  --location eastus \
  --node-count 2 \
  --node-vm-size Standard_D2_v2

az aks get-credentials --name test-cluster --resource-group my-rg
```

## Safety Checks

- [ ] Validate platform is supported
- [ ] Check required CLI tools installed
- [ ] Verify cloud credentials (if applicable)
- [ ] Confirm cluster name doesn't exist
- [ ] For cloud: Estimate costs before creation

## Related

- [k8s.cluster.delete](./k8s.cluster.delete.md) - Delete cluster
- [k8s.addon.install](./k8s.addon.install.md) - Install addons after creation
