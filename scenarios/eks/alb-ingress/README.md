# alb-ingress

**Category**: Ingress | **Platform**: EKS | **CNI**: Any

## Overview
AWS ALB Ingress using AWS Load Balancer Controller.

## Prerequisites
- AWS Load Balancer Controller installed
- Subnet tags for ALB auto-discovery

## What This Tests
- ALB provisioning
- Target group binding
- HTTP path routing

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
