# Spec 004: Quick Start Guide

## Running Scenarios

### Prerequisites
- `kubectl` configured with target cluster
- KUTTL installed: `kubectl krew install kuttl`

### Run a Single Scenario
```bash
# Using test.sh wrapper
./scripts/test.sh --scenario scenarios/general/pod-basic

# Direct KUTTL
kubectl kuttl test scenarios/general/pod-basic
```

### Run a Suite
```bash
# All general scenarios
./scripts/test.sh --suite general

# All EKS scenarios
./scripts/test.sh --suite eks
```

### Verify CNI Configuration
```bash
# Check current CNI
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Run CNI-specific scenarios
./scripts/test.sh --suite network --cni cilium
```

## Common Patterns

| Task | Command |
|------|---------|
| Smoke test | `./scripts/test.sh --scenario scenarios/general/pod-basic` |
| Test ingress | `./scripts/test.sh --scenario scenarios/general/ingress-nginx` |
| Test IRSA (EKS) | `./scripts/test.sh --scenario scenarios/eks/irsa-s3` |
