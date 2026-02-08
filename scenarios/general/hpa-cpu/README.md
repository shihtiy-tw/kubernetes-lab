# hpa-cpu

**Category**: Ops | **Platforms**: All | **CNI**: Any

## Overview
Horizontal Pod Autoscaler based on CPU utilization.

## Prerequisites
- metrics-server installed (shared/addons/metrics-server)

## What This Tests
- HPA creation
- Metrics collection
- Autoscaling trigger (target CPU)

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
