# network-policy-deny-all

**Category**: Security | **Platforms**: All | **CNI**: Any (with NetworkPolicy support)

## Overview
Default deny NetworkPolicy demonstrating zero-trust network isolation.

## What This Tests
- NetworkPolicy enforcement
- CNI NetworkPolicy support
- Pod isolation (ingress + egress)

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
