# appgw-ingress

**Category**: Ingress | **Platform**: AKS | **CNI**: Any

## Overview
Azure Application Gateway Ingress Controller (AGIC).

## Prerequisites
- AGIC installed and configured

## What This Tests
- AppGW backend pool registration
- HTTP path routing
- Health checks

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
