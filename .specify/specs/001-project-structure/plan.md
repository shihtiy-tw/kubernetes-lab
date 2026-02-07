# Plan: Project Structure Migration

## Goal
Enforce the immutable project structure defined in Spec 001 across the `kubernetes-lab` monorepo.

## Phases

### Phase 1: Audit
- [ ] Scan root directory for non-compliant files/folders.
- [ ] Verify `shared/` contents are truly shared.
- [ ] Verify platform directories (`eks`, `kind`, `gke`, `aks`) exist.

### Phase 2: Refactoring
- [ ] Move any loose scripts into `scripts/` or `shared/plugins/`.
- [ ] Ensure `docs/` contains `architecture.md`.
- [ ] Standardize `README.md` in root.

### Phase 3: Prevention
- [ ] Add `structure-test.sh` to CI pipeline to fail on loose files.
