---
description: Run KUTTL integration tests for kubernetes-lab scenarios
---

# k8s.test.integration

## Purpose
Execute KUTTL-based integration tests to verify Kubernetes scenarios.

## Usage
```bash
# Single scenario
./scripts/test.sh --scenario scenarios/general/pod-basic

# Full suite
./scripts/test.sh --suite general

# Dry run (show what would be tested)
./scripts/test.sh --suite network --dry-run
```

## Prerequisites
- kubectl configured with target cluster
- KUTTL installed: `kubectl krew install kuttl`

## Suites
| Suite | Description |
|-------|-------------|
| general | Platform-agnostic K8s primitives |
| network | CNI-specific (Cilium, Calico) |
| eks | AWS EKS integrations |
| gke | GCP GKE integrations |
| aks | Azure AKS integrations |
