---
description: Install Kubernetes addons with platform awareness
---

# k8s.addon.install

## Purpose

Install Kubernetes addons (ingress controllers, monitoring, etc.) with platform-specific configurations.

## Platform Support

**Supported Platforms**: `kind`, `eks`, `gke`, `aks`

## Usage

```bash
# Install ingress-nginx on kind
./scripts/k8s.addon.install.sh --platform kind --addon ingress-nginx --cluster dev-local

# Install AWS Load Balancer Controller on EKS
./scripts/k8s.addon.install.sh --platform eks --addon aws-load-balancer-controller --cluster prod

# Install multiple addons
./scripts/k8s.addon.install.sh --platform gke --addon metrics-server,cert-manager --cluster staging

# Install with custom values
./scripts/k8s.addon.install.sh --platform aks --addon ingress-nginx --cluster test --values custom-values.yaml
```

## Parameters

- `--platform` (required) - Target platform: `kind` | `eks` | `gke` | `aks`
- `--addon` (required) - Addon name(s), comma-separated
- `--cluster` (required) - Target cluster name
- `--values` (optional) - Custom Helm values file
- `--version` (optional) - Specific addon version
- `--namespace` (optional) - Target namespace

## Available Addons

| Addon | kind | EKS | GKE | AKS |
|-------|------|-----|-----|-----|
| ingress-nginx | ✅ | ✅ | ✅ | ✅ |
| cert-manager | ✅ | ✅ | ✅ | ✅ |
| metrics-server | ✅ | ✅ | ✅ | ✅ |
| aws-load-balancer-controller | ❌ | ✅ | ❌ | ❌ |
| external-dns | ✅ | ✅ | ✅ | ✅ |
| cluster-autoscaler | ❌ | ✅ | GKE Native | AKS Native |
| karpenter | ❌ | ✅ | ❌ | ❌ |

## Prerequisites

- kubectl configured for target cluster
- Helm installed
- Platform-specific permissions (IAM roles, etc.)

## Steps

1. Validate platform and addon
2. Switch kubectl context to cluster
3. Check addon prerequisites
4. Apply platform-specific configuration
5. Install via Helm/kubectl
6. Verify addon is running
7. Output addon status

## Platform-Specific Behavior

### kind
- Uses NodePort for ingress
- No cloud-specific integrations

### EKS
- Configures IAM roles for service accounts (IRSA)
- Uses AWS-specific annotations
- Integrates with AWS services

### GKE
- Uses GCP-specific annotations
- Integrates with Cloud Load Balancing
- Leverages Workload Identity

### AKS
- Uses Azure-specific annotations
- Integrates with Azure Load Balancer
- Leverages Pod Identity

## Safety Checks

- [ ] Validate addon supported on platform
- [ ] Check cluster connectivity
- [ ] Verify prerequisites met
- [ ] Confirm namespace exists/create

## Related

- [k8s.cluster.create](./k8s.cluster.create.md) - Create cluster first
- [k8s.scenario.run](./k8s.scenario.run.md) - Run scenarios using addons
