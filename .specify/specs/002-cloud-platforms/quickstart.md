# Quickstart: Creating a New Platform

## Prerequisites
- Cloud provider CLI installed (`az`, `gcloud`, etc.)
- `kubectl` installed
- `helm` installed

## Steps
1. **Create Directory**: `mkdir -p <platform>/{clusters,addons,scenarios,tests,utils}`
2. **Implement Create Script**: Copy `shared/templates/cluster-create.sh` to `<platform>/clusters/` and implement the logic.
3. **Implement Delete Script**: Copy `shared/templates/cluster-delete.sh` to `<platform>/clusters/` and implement the logic.
4. **Test**: Run `./<platform>/clusters/<platform>-cluster-create.sh --dry-run` to verify flags.
