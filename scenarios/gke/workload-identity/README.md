# workload-identity

**Category**: Identity | **Platform**: GKE | **CNI**: Any

## Overview
GKE Workload Identity to access GCP APIs.

## Prerequisites
- GKE cluster with Workload Identity enabled
- GSA (GCP Service Account) bound to KSA

## What This Tests
- Workload Identity token projection
- GCP API access from pod
- Credential chain resolution

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
