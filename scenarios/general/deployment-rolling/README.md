# deployment-rolling

**Category**: Workload | **Platforms**: All | **CNI**: Any

## Overview
Deployment with rolling update strategy, verifying ReplicaSet management.

## What This Tests
- Deployment creation
- Rolling update strategy
- ReplicaSet scaling
- Pod replacement

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
