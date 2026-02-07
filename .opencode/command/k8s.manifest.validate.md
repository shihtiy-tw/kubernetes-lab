---
description: Validate Kubernetes manifests with platform-specific rules
---

# k8s.manifest.validate

## Purpose

Validate Kubernetes manifests using kubeval, kubeconform, and platform-specific linters.

## Platform Support

**Supported Platforms**: `kind`, `eks`, `gke`, `aks`

## Usage

```bash
# Validate manifests for EKS
./scripts/k8s.manifest.validate.sh --platform eks --path eks/scenarios/load-balancers/

# Validate against specific K8s version
./scripts/k8s.manifest.validate.sh --platform gke --path gke/addons/ --k8s-version 1.28

# Validate with strict mode
./scripts/k8s.manifest.validate.sh --platform aks --path aks/clusters/ --strict

# Validate all manifests for platform
./scripts/k8s.manifest.validate.sh --platform kind --all
```

## Parameters

- `--platform` (required) - Target platform: `kind` | `eks` | `gke` | `aks`
- `--path` (optional) - Path to manifests
- `--all` (optional) - Validate all manifests for platform
- `--k8s-version` (optional) - Kubernetes version to validate against
- `--strict` (optional) - Fail on warnings
- `--output` (optional) - Output format: `text` | `json` | `junit`

## Prerequisites

- kubeconform or kubeval installed
- Kubernetes schema files
- Platform-specific CRD schemas

## Steps

1. Validate platform
2. Collect manifest files
3. Download/update schemas
4. Run kubeconform validation
5. Run platform-specific checks
6. Aggregate results
7. Output report

## Validation Checks

### All Platforms
- Valid YAML syntax
- Valid Kubernetes API resources
- Required fields present
- Correct API versions

### Platform-Specific

| Platform | Additional Checks |
|----------|------------------|
| kind | Local path references |
| EKS | AWS-specific annotations, IRSA config |
| GKE | GCP annotations, Workload Identity |
| AKS | Azure annotations, Pod Identity |

## CRD Schema Sources

```
schemas/
├── kubernetes/           # Core K8s schemas
├── eks/                  # AWS CRDs
│   ├── eni-config.json
│   └── security-group-policy.json
├── gke/                  # GCP CRDs
└── aks/                  # Azure CRDs
```

## Safety Checks

- [ ] Validate path exists
- [ ] Check schema files available
- [ ] Verify K8s version supported

## Related

- [k8s.scenario.run](./k8s.scenario.run.md) - Deploy validated manifests
- [k8s.test.integration](./k8s.test.integration.md) - Test after validation
