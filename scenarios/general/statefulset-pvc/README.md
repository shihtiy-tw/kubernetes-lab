# statefulset-pvc

**Category**: Workload | **Platforms**: All | **CNI**: Any

## Overview
StatefulSet with volumeClaimTemplates for persistent storage.

## Prerequisites
- StorageClass available (default or specific)

## What This Tests
- StatefulSet ordering (pod-0, pod-1, pod-2)
- PVC creation per pod
- Stable network identity

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
