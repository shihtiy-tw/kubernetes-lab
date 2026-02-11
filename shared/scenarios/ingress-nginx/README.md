# ingress-nginx

**Category**: Network | **Platforms**: All | **CNI**: Any

## Overview
Ingress with Nginx controller for HTTP routing.

## Prerequisites
- ingress-nginx controller installed (shared/addons/ingress-nginx)

## What This Tests
- Ingress resource creation
- Path-based routing
- Backend service routing

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
