# pd-balanced

**Category**: Storage | **Platform**: GKE | **CNI**: Any

## Overview
GCE Persistent Disk with pd-balanced type.

## What This Tests
- PD-CSI dynamic provisioning
- StorageClass binding
- Volume attachment

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
