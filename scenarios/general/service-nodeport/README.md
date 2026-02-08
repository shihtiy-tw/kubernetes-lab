# service-nodeport

**Category**: Network | **Platforms**: All | **CNI**: Any

## Overview
NodePort service for external access.

## What This Tests
- NodePort allocation
- External accessibility (via node IP:port)
- Port range (30000-32767)

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
