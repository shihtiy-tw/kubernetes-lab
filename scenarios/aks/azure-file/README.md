# azure-file

**Category**: Storage | **Platform**: AKS | **CNI**: Any

## Overview
Azure Files with SMB share for ReadWriteMany access.

## What This Tests
- Azure Files CSI dynamic provisioning
- SMB mount
- ReadWriteMany access mode

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
