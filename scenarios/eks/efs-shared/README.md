# efs-shared

**Category**: Storage | **Platform**: EKS | **CNI**: Any

## Overview
EFS shared filesystem with ReadWriteMany access.

## Prerequisites
- EFS CSI Driver installed
- EFS filesystem and access point created

## What This Tests
- EFS dynamic provisioning
- ReadWriteMany access mode
- Multiple pod access to same volume

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
