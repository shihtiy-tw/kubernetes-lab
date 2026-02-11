# prometheus-stack
**Category**: Observability | **Source**: Helm | **Platforms**: All
## Overview
Full monitoring stack: Prometheus, Grafana, Alertmanager, and pre-configured dashboards.
## Quick Start
```bash
./install.sh
# Access Grafana (default: admin/prom-operator)
kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring
```
## See Also
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
