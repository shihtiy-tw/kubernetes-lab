# Research: 12-Factor CLI Analysis

## Context
Command-line interfaces (CLIs) are the primary way users interact with the lab. Inconsistent CLIs lead to frustration and errors.

## Analysis
- **Current State**: EKS scripts and Kind scripts have different flags and output formats.
- **Problem**: Users have to "re-learn" how to use the lab when switching clouds.
- **Solution**: 12-Factor CLI methodology ensures predictability.
  - **Environment parity**: Scripts behave the same in dev/stage/prod.
  - **Explicit dependencies**: Scripts check for required tools (kubectl, helm).
  - **Logs as event streams**: Standard output format.

## Decision
Enforce a strict "Standard Interface" for all cluster lifecycle scripts.
- **Pros**: `k8s.cluster.create` wrapper can be dumb and just pass flags.
- **Cons**: Requires refactoring existing scripts.
