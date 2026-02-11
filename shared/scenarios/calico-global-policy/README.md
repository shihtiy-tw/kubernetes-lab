# calico-global-policy

**Category**: Network | **Platforms**: All | **CNI**: Calico

## Overview
Cluster-wide GlobalNetworkPolicy using Calico.

## Prerequisites
- Calico CNI installed

## What This Tests
- GlobalNetworkPolicy CRD
- Cluster-wide policy enforcement
- Default deny rules

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
