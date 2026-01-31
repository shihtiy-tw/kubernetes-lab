# Monitoring Configuration

This directory contains monitoring configurations for kubernetes-lab.

## Structure

```
monitoring/
├── README.md             # This file
├── dashboards/           # Grafana dashboard definitions
│   ├── cluster-overview.json
│   └── addon-health.json
├── alerts/               # Prometheus alert rules
│   ├── cluster-alerts.yaml
│   └── addon-alerts.yaml
└── logs/                 # Logging configurations
    └── fluent-bit-config.yaml
```

## Grafana Dashboards

Import dashboards into Grafana:

1. Open Grafana UI
2. Navigate to Dashboards → Import
3. Upload JSON file or paste contents
4. Select data source
5. Click Import

### Available Dashboards

| Dashboard | Description | ID |
|-----------|-------------|-----|
| Cluster Overview | Cluster health metrics | 1000 |
| Addon Health | Addon status and metrics | 1001 |

## Prometheus Alerts

Apply alert rules to Prometheus:

```bash
kubectl apply -f monitoring/alerts/
```

Or via kube-prometheus-stack Helm values:

```yaml
additionalPrometheusRulesMap:
  rule-name:
    groups:
      - name: kubernetes-lab
        rules:
          # ... rules from alerts/*.yaml
```

### Alert Severity Levels

| Level | Description | Response |
|-------|-------------|----------|
| `critical` | Immediate action required | Page on-call |
| `warning` | Attention needed soon | Slack notification |
| `info` | Informational | Log only |

## Logging

### Fluent Bit Configuration

Apply to cluster:

```bash
kubectl apply -f monitoring/logs/fluent-bit-config.yaml
```

### Log Outputs

| Output | Destination | Use Case |
|--------|-------------|----------|
| Elasticsearch | Centralized logs | Search & analysis |
| CloudWatch | AWS integration | AWS-native logging |
| Loki | Grafana stack | Cost-effective |

## Quick Start

1. Install kube-prometheus-stack:
   ```bash
   helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
     --namespace monitoring --create-namespace \
     -f monitoring/prometheus-values.yaml
   ```

2. Import dashboards (automatic with Helm values)

3. Apply alert rules:
   ```bash
   kubectl apply -f monitoring/alerts/
   ```

---

*Last updated: 2026-01-31*
