---
description: Run KUTTL integration tests with platform awareness
---

# k8s.test.integration

## Purpose

Execute KUTTL integration tests against Kubernetes clusters with platform-specific configurations.

## Platform Support

**Supported Platforms**: `kind`, `eks`, `gke`, `aks`

## Usage

```bash
# Run all tests on kind
./scripts/k8s.test.integration.sh --platform kind --cluster dev-local

# Run specific test suite on EKS
./scripts/k8s.test.integration.sh --platform eks --cluster prod --suite addons

# Run with parallel execution
./scripts/k8s.test.integration.sh --platform gke --cluster staging --parallel 4

# Run with verbose output
./scripts/k8s.test.integration.sh --platform aks --cluster test --verbose
```

## Parameters

- `--platform` (required) - Target platform: `kind` | `eks` | `gke` | `aks`
- `--cluster` (required) - Target cluster name
- `--suite` (optional) - Test suite: `addons` | `scenarios` | `all` (default: all)
- `--parallel` (optional) - Parallel test count (default: 1)
- `--verbose` (optional) - Detailed output
- `--timeout` (optional) - Test timeout (default: 5m)

## Prerequisites

- KUTTL installed (`kubectl kuttl`)
- kubectl configured for cluster
- Test manifests in `tests/` directory

## Steps

1. Validate platform and cluster
2. Switch kubectl context
3. Check KUTTL installed
4. Select test suite
5. Apply platform-specific test config
6. Execute KUTTL tests
7. Collect and format results
8. Generate report

## Test Directory Structure

```
{platform}/tests/
├── kuttl-test.yaml         # KUTTL configuration
├── addons/                  # Addon tests
│   ├── ingress-nginx/
│   │   ├── 00-install.yaml
│   │   ├── 01-assert.yaml
│   │   └── 02-cleanup.yaml
│   └── cert-manager/
├── scenarios/               # Scenario tests
│   └── load-balancers/
└── e2e/                     # End-to-end tests
```

## Platform-Specific Test Configuration

### kind
- Fast execution
- No cloud resource cleanup
- Uses local images

### EKS/GKE/AKS
- Longer timeouts for cloud resources
- Cloud-specific assertions
- Resource cleanup critical

## Safety Checks

- [ ] Validate cluster connectivity
- [ ] Check KUTTL installed
- [ ] Verify test manifests exist
- [ ] Confirm test namespace isolation

## Related

- [k8s.scenario.run](./k8s.scenario.run.md) - Run scenarios before testing
- [k8s.addon.install](./k8s.addon.install.md) - Install addons to test
