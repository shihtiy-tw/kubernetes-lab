# Kind - Local Kubernetes Testing

Local Kubernetes clusters using [kind](https://kind.sigs.k8s.io/) for testing shared plugins and generic scenarios.

## Purpose

- Test shared plugins before deploying to cloud clusters
- Validate Kubernetes manifests locally
- Run KUTTL integration tests
- Develop and debug scenarios

---

## Quick Start

```bash
# Create a basic cluster
./clusters/basic/create.sh --name test-cluster

# Create multi-node cluster
./clusters/multi-node/create.sh --name multi-test

# List clusters
kind get clusters

# Delete cluster
kind delete cluster --name test-cluster
```

---

## Structure

| Directory | Purpose |
|-----------|---------|
| `clusters/` | Cluster configuration files |
| `scenarios/` | Test scenarios for validation |
| `tests/` | KUTTL test suites |
| `utils/` | Helper utilities |

---

## Cluster Types

### Basic (Single Node)
Minimal cluster for quick testing.

```bash
cd clusters/basic
./create.sh --name basic
```

### Multi-Node
3-node cluster (1 control-plane + 2 workers) for realistic testing.

```bash
cd clusters/multi-node
./create.sh --name multi
```

### With Ingress
Pre-configured with ingress controller ports exposed.

```bash
cd clusters/ingress
./create.sh --name ingress-test
```

---

## Testing Shared Plugins

```bash
# Create test cluster
./clusters/basic/create.sh --name plugin-test

# Test a shared plugin
cd ../shared/plugins/ingress-nginx
./install.sh --cluster plugin-test --context kind-plugin-test

# Run smoke test
cd ../../kind/tests
./test-smoke.sh --context kind-plugin-test

# Cleanup
kind delete cluster --name plugin-test
```

---

## KUTTL Tests

```bash
# Run all kind tests
kubectl kuttl test --config tests/kuttl-test.yaml

# Run specific test
kubectl kuttl test --config tests/kuttl-test.yaml --test ingress-nginx
```

---

## Prerequisites

- Docker or Podman
- kind CLI: `go install sigs.k8s.io/kind@latest`
- kubectl
- (Optional) kuttl: `kubectl krew install kuttl`
