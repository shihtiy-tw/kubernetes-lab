# workload-id

**Category**: Identity | **Platform**: AKS | **CNI**: Any

## Overview
Azure Workload Identity for accessing Azure resources.

## Prerequisites
- AKS cluster with Workload Identity enabled
- Federated identity credential configured

## What This Tests
- Workload Identity token projection
- Azure SDK credential chain
- Azure resource access

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
