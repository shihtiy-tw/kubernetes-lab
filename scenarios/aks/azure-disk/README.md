# azure-disk

**Category**: Storage | **Platform**: AKS | **CNI**: Any

## Overview
Azure Disk with Premium SSD.

## What This Tests
- Azure Disk CSI dynamic provisioning
- Premium SSD performance tier
- Volume attachment

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
