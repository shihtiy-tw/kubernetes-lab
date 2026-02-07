# Data Model: Script Interface Schema

## Cluster Creation Script (`*-cluster-create.sh`)

| Flag | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `--name` | String | Name of the cluster | Yes | - |
| `--region` | String | Cloud region/zone | Yes | - |
| `--node-count` | Integer | Initial node count | No | 2 |
| `--dry-run` | Boolean | Print commands without executing | No | false |
| `--help` | Boolean | Show usage | No | - |
| `--version` | Boolean | Show script version | No | - |

## Cluster Deletion Script (`*-cluster-delete.sh`)

| Flag | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `--name` | String | Name of the cluster | Yes | - |
| `--region` | String | Cloud region/zone | Yes | - |
| `--force` | Boolean | Skip confirmation | No | false |

## CLI Output Format (Standard)

```text
[INFO] <timestamp> Starting cluster creation...
[WARN] <timestamp> Resource group already exists...
[ERROR] <timestamp> Failed to create node pool: <error>
```
