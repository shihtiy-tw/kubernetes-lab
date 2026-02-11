# pdb-disruption

**Category**: Ops | **Platforms**: All | **CNI**: Any

## Overview
Pod Disruption Budget enforcement.

## What This Tests
- PDB creation
- minAvailable/maxUnavailable enforcement
- Eviction protection

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
