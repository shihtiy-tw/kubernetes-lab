# ebs-retain

**Category**: Storage | **Platform**: EKS | **CNI**: Any

## Overview
EBS gp3 volume with Retain reclaim policy.

## Prerequisites
- EBS CSI Driver installed
- gp3 StorageClass

## What This Tests
- PVC provisioning with EBS CSI
- Volume binding
- Retain policy (volume persists after PVC deletion)

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
