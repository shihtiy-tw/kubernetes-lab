# Research: Addon Ecosystem Design

## Context
Kubernetes addons extend cluster functionality. Managing addons across multiple cloud providers presents challenges in consistency and maintainability.

## Analysis

### Challenge 1: Shared vs Platform-Specific
Some addons (cert-manager) work identically everywhere. Others (AWS LB Controller) require cloud-specific IAM.

**Decision**: 
- Shared addons → `shared/addons/`
- Platform-specific → `<platform>/addons/`

### Challenge 2: Installation Methods
Addons can be installed via:
1. Helm charts (most common)
2. Raw manifests (simple addons)
3. Cloud provider APIs (managed addons like EKS Addons)
4. Operators (e.g., OLM)

**Decision**: Prefer Helm where available for consistency. Fall back to manifests or APIs when Helm is not suitable.

### Challenge 3: Idempotency
Running `install.sh` twice should not fail or create duplicates.

**Decision**: Use `helm upgrade --install` pattern, which handles both fresh install and upgrade.

### Challenge 4: CRD Management
CRDs are cluster-scoped and can conflict across namespaces.

**Decision**: 
- Install: Create CRDs automatically
- Uninstall: Preserve CRDs by default, offer `--delete-crds` flag

## Addon Selection Criteria

1. **Maturity**: CNCF graduated/incubating preferred
2. **Maintenance**: Active development, recent releases
3. **Documentation**: Official docs available
4. **Compatibility**: Works with Kubernetes 1.28+

## Alternatives Considered

### 1. Single Install Script per Platform
Instead of per-addon scripts, one `install-all.sh`.
**Rejected**: Less flexible, harder to troubleshoot individual addons.

### 2. Terraform/Pulumi for Addons
Infrastructure-as-code for addon management.
**Rejected**: Adds complexity, less portable than shell scripts.

### 3. ArgoCD ApplicationSets
GitOps-based addon management.
**Deferred**: Good for production, but scripts are needed for initial bootstrap.
