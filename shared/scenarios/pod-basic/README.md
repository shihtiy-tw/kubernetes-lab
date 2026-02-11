# pod-basic

**Category**: Workload | **Platforms**: All | **CNI**: Any

## Overview
Simple nginx pod deployment to verify basic cluster connectivity and CNI functionality.

## What This Tests
- Pod scheduling
- Container runtime
- CNI networking (pod gets IP)
- DNS resolution

## Quick Start
```bash
kubectl apply -f manifests/
kubectl wait --for=condition=Ready pod/nginx -n scenario-pod-basic --timeout=60s
kubectl kuttl test .
```

## Expected Outcome
- Pod is Running
- Pod has IP address assigned
- Pod can reach kubernetes.default.svc
