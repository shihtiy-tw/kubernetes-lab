# service-clusterip

**Category**: Network | **Platforms**: All | **CNI**: Any

## Overview
Internal ClusterIP service with DNS resolution verification.

## What This Tests
- Service creation
- ClusterIP assignment
- DNS record creation (service.namespace.svc.cluster.local)
- Pod-to-service communication

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
