# irsa-s3

**Category**: Identity | **Platform**: EKS | **CNI**: Any

## Overview
IRSA (IAM Roles for Service Accounts) to access S3 bucket.

## Prerequisites
- EKS cluster with OIDC provider
- IAM role with S3 permissions
- Service account annotated with role ARN

## What This Tests
- IRSA token projection
- AWS SDK credential chain
- S3 bucket access from pod

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
