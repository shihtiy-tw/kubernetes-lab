# job-cronjob

**Category**: Workload | **Platforms**: All | **CNI**: Any

## Overview
Batch job and CronJob scheduling.

## What This Tests
- Job completion
- CronJob scheduling
- Pod termination after completion

## Quick Start
```bash
kubectl apply -f manifests/
kubectl kuttl test .
```
