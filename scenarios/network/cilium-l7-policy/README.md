# cilium-l7-policy

**Category**: Network | **Platforms**: All | **CNI**: Cilium

## Overview
HTTP-aware L7 network policy using Cilium.

## Prerequisites
- Cilium CNI installed

## What This Tests
- CiliumNetworkPolicy CRD
- L7 HTTP method filtering
- Path-based allow rules

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
