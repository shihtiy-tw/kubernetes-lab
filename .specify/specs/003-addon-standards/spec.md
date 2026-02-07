---
id: spec-003
title: Addon Standards & Ecosystem
type: standard
priority: critical
status: proposed
dependencies: [spec-001, spec-002]
tags: [governance, addons, kubernetes]
---

# Spec 003: Addon Standards & Ecosystem

## Overview
This specification defines the standard for implementing Kubernetes addons across all platforms in the `kubernetes-lab`. It establishes:
1. Classification rules (Shared vs Platform-Specific)
2. Directory and file structure requirements
3. Script interface standards
4. The complete addon catalog
5. **Addon status verification tools**

## Addon Status Verification

### Quick Check Command
A global utility script to check all installed addons:

```bash
# Check all addons on current cluster
./scripts/addon-status.sh

# Check specific platform addons
./scripts/addon-status.sh --platform eks

# Output format
ADDON                           STATUS    VERSION   NAMESPACE
cert-manager                    ✅ OK     v1.14.0   cert-manager
ingress-nginx                   ✅ OK     4.9.0     ingress-nginx
prometheus-stack                ❌ NOT    -         -
aws-load-balancer-controller    ✅ OK     2.7.0     kube-system
```

### Per-Addon Status Script
Each addon directory MUST also include a `status.sh` script:

```bash
./shared/addons/cert-manager/status.sh
# Output: cert-manager v1.14.0 - Running (3/3 pods ready)
```


## Classification Rules

### Shared Addons (`shared/addons/`)
Addons that:
- Work identically across all Kubernetes clusters
- Do NOT require cloud-provider-specific configuration (IAM, service accounts, etc.)
- Can be installed with generic `kubectl` or `helm` commands

**Examples**: cert-manager, metrics-server, argocd, prometheus-stack

### Platform-Specific Addons (`<platform>/addons/`)
Addons that:
- Require cloud-provider CLI integration (gcloud, az, aws)
- Configure IAM roles, service accounts, or cloud resources
- Use provider-specific Helm values or manifests

**Examples**: AWS Load Balancer Controller (IRSA), GKE Workload Identity, AKS Key Vault CSI

## Standard Addon Structure

Every addon directory MUST contain:

```text
<addon-name>/
├── install.sh      # 12-factor compliant installation
├── uninstall.sh    # Safe removal with cleanup
├── upgrade.sh      # In-place upgrade
├── status.sh       # Check if addon is installed and healthy
└── README.md       # Usage documentation
```

Optional files:
- `values.yaml` - Default Helm values
- `config/` - Additional configuration files
- `examples/` - Usage examples

## Script Interface Standards

All scripts MUST support:
- `--help` - Display usage information
- `--version` - Display script version
- `--dry-run` - Print commands without executing
- `--namespace` - Target namespace (where applicable)

### install.sh
- MUST be idempotent (safe to run multiple times)
- MUST validate prerequisites before installation
- MUST output installed version on success

### uninstall.sh
- MUST support `--force` to skip confirmation
- MUST clean up CRDs and resources (configurable)
- MUST NOT fail if addon is not installed

### upgrade.sh
- MUST validate current installation exists
- MUST support `--to-version` flag
- MUST perform pre-upgrade checks

## Complete Addon Catalog

### Shared Addons (8 total)

| Addon | Category | Helm Chart | Priority |
|-------|----------|------------|----------|
| cert-manager | TLS | jetstack/cert-manager | High |
| metrics-server | Observability | metrics-server/metrics-server | High |
| ingress-nginx | Networking | ingress-nginx/ingress-nginx | High |
| external-dns | Networking | external-dns/external-dns | High |
| prometheus-stack | Observability | prometheus-community/kube-prometheus-stack | High |
| argocd | GitOps | argo/argo-cd | Medium |
| external-secrets | Security | external-secrets/external-secrets | Medium |
| keda | Autoscaling | kedacore/keda | Medium |

### EKS Addons (8 total)

| Addon | Category | Source | Priority |
|-------|----------|--------|----------|
| aws-load-balancer-controller | Networking | Helm | High |
| cluster-autoscaler | Autoscaling | Helm | High |
| karpenter | Autoscaling | Helm | High |
| aws-ebs-csi-driver | Storage | EKS Addon | High |
| eks-pod-identity-agent | Identity | EKS Addon | High |
| cloudwatch-observability | Observability | EKS Addon | Medium |
| secrets-store-csi-driver | Security | Helm | Medium |
| aws-efs-csi-driver | Storage | EKS Addon | Medium |

### GKE Addons (6 total)

| Addon | Category | Source | Priority |
|-------|----------|--------|----------|
| workload-identity | Identity | gcloud | High |
| config-connector | Infrastructure | Helm/gcloud | High |
| cloud-sql-proxy | Database | Manifest | High |
| filestore-csi | Storage | GKE Addon | Medium |
| cloud-armor | Security | gcloud | Medium |
| anthos-service-mesh | Service Mesh | gcloud | Medium |

### AKS Addons (6 total)

| Addon | Category | Source | Priority |
|-------|----------|--------|----------|
| aad-pod-identity | Identity | az | High |
| azure-disk-csi | Storage | AKS Addon | High |
| azure-keyvault-csi | Security | AKS Addon | High |
| appgw-ingress | Networking | AKS Addon | High |
| azure-file-csi | Storage | AKS Addon | Medium |
| azure-policy | Governance | AKS Addon | Medium |

### Kind Addons (3 total)

| Addon | Category | Source | Priority |
|-------|----------|--------|----------|
| local-path-provisioner | Storage | Manifest | High |
| metallb | Networking | Helm | High |
| registry | Development | Manifest | Medium |

## Total: 31 Addons
- Shared: 8
- EKS: 8
- GKE: 6
- AKS: 6
- Kind: 3
