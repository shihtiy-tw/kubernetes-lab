---
description: Deploy Kubernetes scenarios with platform awareness
---

# k8s.scenario.run

## Purpose

Deploy and test Kubernetes scenarios with platform-specific manifest adaptations.

## Platform Support

**Supported Platforms**: `kind`, `eks`, `gke`, `aks`

## Usage

```bash
# Run load-balancer scenario on EKS
./scripts/k8s.scenario.run.sh --platform eks --scenario load-balancers/alb-https --cluster prod

# Run scenario on kind
./scripts/k8s.scenario.run.sh --platform kind --scenario ingress-basic --cluster dev-local

# Run with cleanup after
./scripts/k8s.scenario.run.sh --platform gke --scenario pod-identity --cluster staging --cleanup

# Dry run (show manifests only)
./scripts/k8s.scenario.run.sh --platform aks --scenario load-balancers --cluster test --dry-run
```

## Parameters

- `--platform` (required) - Target platform: `kind` | `eks` | `gke` | `aks`
- `--scenario` (required) - Scenario path (e.g., `load-balancers/alb-https`)
- `--cluster` (required) - Target cluster name
- `--cleanup` (optional) - Delete resources after testing
- `--dry-run` (optional) - Show manifests without applying
- `--wait` (optional) - Wait for deployment completion

## Prerequisites

- Cluster exists and is accessible
- Required addons installed
- Scenario manifests exist

## Steps

1. Validate platform and scenario
2. Switch kubectl context
3. Check scenario prerequisites
4. Apply platform-specific transformations
5. Deploy manifests
6. Wait for deployment (if --wait)
7. Run validation tests
8. Cleanup (if --cleanup)

## Platform-Specific Manifest Transformations

### Load Balancer Annotations

| Platform | Annotation Key | Example Value |
|----------|----------------|---------------|
| kind | service.type | NodePort |
| EKS | service.beta.kubernetes.io/aws-load-balancer-type | nlb |
| GKE | cloud.google.com/neg | '{"ingress": true}' |
| AKS | service.beta.kubernetes.io/azure-load-balancer-internal | "true" |

### Storage Class Mapping

| Platform | Default Storage Class |
|----------|-----------------------|
| kind | standard |
| EKS | gp3 |
| GKE | standard-rwo |
| AKS | managed-premium |

## Scenario Directory Structure

```
{platform}/scenarios/{scenario}/
├── deploy.sh           # Platform-specific deploy script
├── manifests/
│   ├── base/           # Base manifests (kustomize)
│   └── overlays/
│       ├── kind/
│       ├── eks/
│       ├── gke/
│       └── aks/
├── tests/
│   └── validate.sh
└── README.md
```

## Safety Checks

- [ ] Validate scenario exists
- [ ] Check cluster connectivity
- [ ] Verify prerequisites met
- [ ] Confirm namespace isolation

## Related

- [k8s.addon.install](./k8s.addon.install.md) - Install required addons
- [k8s.test.integration](./k8s.test.integration.md) - Run integration tests
