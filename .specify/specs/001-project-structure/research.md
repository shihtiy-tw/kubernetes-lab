# Research: Monorepo Strategy

## Context
We are managing 4 Kubernetes platforms (EKS, GKE, AKS, Kind) with shared logic.

## Analysis
- **Shared Logic**: Scenarios (apps) and Addons (e.g., ingress-nginx) are largely platform-agnostic but have platform-specific installation wrappers.
- **Agent Context**: Agents function better with a predictable structure. 70% of "Agent lost" errors are due to inconsistent file paths.

## Decision
Adopt a strict "Platform Module" vs "Shared Core" architecture.
- **Pros**: Clear separation of concerns. Easy to add new platforms (Oracle, DigitalOcean).
- **Cons**: Slightly deeper directory nesting.

## Alternatives Considered
1. **Polyrepo**: One repo per cloud.
   - *Rejected*: Too hard to share scenario logic and keep updates in sync.
2. **Flat Structure**: All scripts in `scripts/`.
   - *Rejected*: Unmanageable with 4 clouds * 20 scenarios.
