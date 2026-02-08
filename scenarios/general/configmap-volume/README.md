# configmap-volume

**Category**: Config | **Platforms**: All | **CNI**: Any

## Overview
Mount ConfigMap as a volume in a pod.

## What This Tests
- ConfigMap creation
- Volume mounting
- File projection into pod

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
