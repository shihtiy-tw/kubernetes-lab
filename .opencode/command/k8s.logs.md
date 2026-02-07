---
description: Aggregate and view logs from Kubernetes clusters with platform awareness
---

# k8s.logs

## Purpose

Aggregate and view logs from Kubernetes pods and services using platform-native tools.

## Platform Support

**Supported Platforms**: `kind`, `eks`, `gke`, `aks`

## Usage

```bash
# View logs from specific deployment on kind
./scripts/k8s.logs.sh --platform kind --cluster dev-local --deployment nginx

# Tail logs from EKS with namespace filter
./scripts/k8s.logs.sh --platform eks --cluster prod --namespace kube-system --follow

# View logs from all pods with label
./scripts/k8s.logs.sh --platform gke --cluster staging --label app=api --since 1h

# Export logs to file
./scripts/k8s.logs.sh --platform aks --cluster test --deployment backend --export logs.txt

# Use platform-native log aggregation
./scripts/k8s.logs.sh --platform eks --cluster prod --native
```

## Parameters

- `--platform` (required) - Target platform: `kind` | `eks` | `gke` | `aks`
- `--cluster` (required) - Target cluster name
- `--deployment` (optional) - Deployment name
- `--namespace` (optional) - Namespace filter (default: all)
- `--label` (optional) - Label selector
- `--since` (optional) - Time filter: `1m` | `1h` | `1d`
- `--follow` (optional) - Tail mode
- `--native` (optional) - Use platform-native logging
- `--export` (optional) - Export to file

## Prerequisites

- kubectl configured for cluster
- For `--native`: Platform-specific CLI tools

## Steps

1. Validate platform and cluster
2. Switch kubectl context
3. Select pods by deployment/label/namespace
4. Fetch logs (kubectl or native)
5. Apply filters
6. Stream or export

## Platform-Specific Native Logging

### kind
- Uses `kubectl logs` directly
- No external log aggregation

### EKS (CloudWatch)
```bash
aws logs filter-log-events \
  --log-group-name /aws/eks/cluster/containers \
  --filter-pattern "..."
```

### GKE (Cloud Logging)
```bash
gcloud logging read \
  'resource.type="k8s_container"' \
  --project my-project
```

### AKS (Azure Monitor)
```bash
az monitor log-analytics query \
  --workspace my-workspace \
  --analytics-query "ContainerLog | where ..."
```

## Multi-Pod Log Aggregation

Use stern for multi-pod tailing:
```bash
stern --context {cluster} --namespace {ns} {pod-query}
```

## Safety Checks

- [ ] Validate cluster connectivity
- [ ] Check namespace access
- [ ] Verify log permissions

## Related

- [k8s.scenario.run](./k8s.scenario.run.md) - Deploy to generate logs
- [k8s.test.integration](./k8s.test.integration.md) - Debug test failures
