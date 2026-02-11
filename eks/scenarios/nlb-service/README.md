# nlb-service

**Category**: Network | **Platform**: EKS | **CNI**: Any

## Overview
AWS Network Load Balancer via Service type LoadBalancer.

## Prerequisites
- AWS Load Balancer Controller installed

## What This Tests
- NLB provisioning
- TCP load balancing
- Target group registration

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
