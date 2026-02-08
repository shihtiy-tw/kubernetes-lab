# neg-ingress

**Category**: Ingress | **Platform**: GKE | **CNI**: Any

## Overview
GKE Ingress with Network Endpoint Groups (NEG).

## Prerequisites
- GKE Ingress controller enabled

## What This Tests
- NEG-based backend binding
- Container-native load balancing
- HTTP path routing

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
