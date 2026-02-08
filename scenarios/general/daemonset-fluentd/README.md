# daemonset-fluentd

**Category**: Workload | **Platforms**: All | **CNI**: Any

## Overview
DaemonSet for log collection pattern (fluentd-like).

## What This Tests
- DaemonSet scheduling (one pod per node)
- Node selector/tolerations
- Log volume mounting

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
