# Data Model: Addon Script Interface

## Directory Structure

```text
<addon-name>/
├── install.sh      # Required
├── uninstall.sh    # Required
├── upgrade.sh      # Required
├── README.md       # Required
├── values.yaml     # Optional - Helm overrides
└── config/         # Optional - Additional configs
```

## Script Interface: install.sh

| Flag | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `--namespace` | String | Target namespace | No | addon-specific |
| `--release-name` | String | Helm release name | No | addon name |
| `--version` | String | Chart/addon version | No | latest |
| `--values` | Path | Custom values file | No | - |
| `--dry-run` | Boolean | Print without executing | No | false |
| `--help` | Boolean | Show usage | No | - |
| `--script-version` | Boolean | Show script version | No | - |

**Exit Codes**:
- `0` - Success
- `1` - General error
- `2` - Missing dependencies
- `3` - Validation failed

## Script Interface: uninstall.sh

| Flag | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `--namespace` | String | Target namespace | No | addon-specific |
| `--release-name` | String | Helm release name | No | addon name |
| `--delete-crds` | Boolean | Also delete CRDs | No | false |
| `--force` | Boolean | Skip confirmation | No | false |
| `--dry-run` | Boolean | Print without executing | No | false |
| `--help` | Boolean | Show usage | No | - |

## Script Interface: upgrade.sh

| Flag | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `--namespace` | String | Target namespace | No | addon-specific |
| `--release-name` | String | Helm release name | No | addon name |
| `--to-version` | String | Target version | No | latest |
| `--values` | Path | Custom values file | No | - |
| `--dry-run` | Boolean | Print without executing | No | false |
| `--help` | Boolean | Show usage | No | - |

## Output Format

```text
[INFO] 2026-02-07 13:55:00 Starting cert-manager installation...
[INFO] 2026-02-07 13:55:01 Adding Helm repository...
[INFO] 2026-02-07 13:55:05 Installing chart version 1.14.0...
[INFO] 2026-02-07 13:55:30 Waiting for pods to be ready...
[INFO] 2026-02-07 13:55:45 cert-manager v1.14.0 installed successfully!
```

## README.md Template

```markdown
# <Addon Name>

**Category**: <Networking|Storage|Observability|Security|GitOps|Autoscaling>
**Source**: <Helm|Manifest|Cloud API>
**Chart**: <chart-repo/chart-name>

## Overview
<Brief description>

## Prerequisites
- <Required tools>
- <Required permissions>

## Quick Start
\`\`\`bash
./install.sh --namespace <ns>
\`\`\`

## Configuration
| Parameter | Description | Default |
|-----------|-------------|---------|

## Troubleshooting
<Common issues and solutions>
```
