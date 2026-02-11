# secret-env

**Category**: Config | **Platforms**: All | **CNI**: Any

## Overview
Inject Secret as environment variables.

## What This Tests
- Secret creation
- Environment variable injection
- Base64 decoding

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
