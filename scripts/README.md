# Utility Scripts

Standardized automation scripts for the Kubernetes Lab.

## Available Scripts

| Script | Purpose |
|--------|---------|
| `setup-dev.sh` | Sets up the local development environment |
| `install-deps.sh` | Installs required CLI tools (kubectl, helm, etc.) |
| `check-versions.sh` | Verifies installed tool versions |
| `addon-status.sh` | Summarizes status of installed addons |
| `test.sh` | Runs the test suite |

## Usage

Most scripts support `--help` for usage information:

```bash
./setup-dev.sh --help
```

## Standards

All scripts in this directory should follow these standards:

1. **Idempotency**: Running a script multiple times should not cause errors.
2. **Help Flag**: Support `--help` and provide usage examples.
3. **Error Handling**: Use `set -e` and provide clear error messages.
4. **Platform Aware**: Detect and handle different operating systems (macOS, Linux).
