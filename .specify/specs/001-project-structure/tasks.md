# Tasks: Project Structure

## Validation
- [ ] Verify root directory only contains allowed folders:
  - `.opencode/`, `.specify/`, `.github/`
  - `aks/`, `eks/`, `gke/`, `kind/`
  - `docs/`, `scripts/`, `shared/`, `tests/`
  - `AGENTS.md`, `BACKLOG.md`, `Makefile`, `README.md`
- [ ] Verify `shared/` subdirectories:
  - `charts/`, `manifests/`, `plugins/`, `scenarios/`
- [ ] Verify `docs/` contains `architecture.md`

## Automation
- [ ] Create `scripts/validate-structure.sh`
- [ ] Add validation step to `Makefile` (`make check-structure`)
