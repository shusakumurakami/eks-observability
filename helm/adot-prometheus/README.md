# ADOT Prometheus Collector Helm Chart

AWS Distro for OpenTelemetry (ADOT) Collector for scraping Prometheus metrics and sending them to Amazon Managed Prometheus (AMP).

## Overview

This Helm chart deploys an ADOT Collector configured to:
- Scrape Prometheus metrics from Kubernetes pods
- Send metrics to Amazon Managed Prometheus (AMP) via remote write
- Use IRSA (IAM Roles for Service Accounts) for AWS authentication

## Prerequisites

1. EKS cluster with IRSA configured
2. **Terraform module deployed**: `managed-prometheus` module creates AMP workspace and IAM role
3. Helm 3.x installed
4. kubectl configured to access your EKS cluster

## Installation

### Step 1: Get Terraform outputs

**Note**: This chart requires the `managed-prometheus` module to be deployed first.

```bash
cd infra/terraform/envs/dev/main

# Uncomment observability_prometheus module first, then get outputs:
export AMP_ENDPOINT=$(terraform output -raw prometheus_workspace_endpoint)
export ADOT_ROLE_ARN=$(terraform output -raw prometheus_adot_collector_role_arn)
```

### Step 2: Install the chart

**Note**: By default, the chart will create the `aws-otel-eks` namespace (controlled by `namespace.create: true` in values.yaml). If you're also deploying the `adot-container-insights` chart, only one chart should create the namespace to avoid conflicts.

```bash
# Install (namespace will be created automatically)
helm install adot-prometheus ./adot-prometheus \
  -f ./adot-prometheus/values/values-dev.yaml \
  --namespace aws-otel-eks

# Upgrade (after initial install)
helm upgrade adot-prometheus ./adot-prometheus \
  -f ./adot-prometheus/values/values-dev.yaml \
  --namespace aws-otel-eks

# If adot-container-insights is also deployed and creates the namespace:
# helm install adot-prometheus ./adot-prometheus \
#   -f ./adot-prometheus/values/values-dev.yaml \
#   --set namespace.create=false \
#   --namespace aws-otel-eks
```

### Step 3: Verify deployment

```bash
# Check pods
kubectl get pods -n aws-otel-eks -l app={{ .Values.resourceNames.appLabel }}

# Check logs
kubectl logs -n aws-otel-eks -l app={{ .Values.resourceNames.appLabel }} --tail=50

# Or with default value:
kubectl get pods -n aws-otel-eks -l app=adot-collector-prometheus
kubectl logs -n aws-otel-eks -l app=adot-collector-prometheus --tail=50
```

## Configuration

### Values

Key configuration values in `values.yaml`:

```yaml
aws:
  region: ap-northeast-1
  clusterName: "your-cluster-name"
  environment: "dev"

amp:
  workspaceEndpoint: "https://aps-workspaces.region.amazonaws.com/workspaces/ws-xxx/"

serviceAccount:
  name: adot-collector-prometheus
  roleArn: "arn:aws:iam::xxx:role/prometheus-irsa"

namespace:
  name: aws-otel-eks
  create: true  # Set to false if namespace is already created by another chart

# Resource naming (customized to avoid conflicts with other ADOT collectors)
resourceNames:
  configMapName: adot-collector-prometheus-config
  deploymentName: adot-collector-prometheus
  containerName: adot-collector-prometheus
  appLabel: adot-collector-prometheus

application:
  namespace: appNamespace  # Namespace to scrape metrics from

replicaCount: 2  # Use 1 to avoid duplicate scraping

config:
  scrapeInterval: 30s
  scrapeTimeout: 10s
```

The `resourceNames` section allows customization of resource names to avoid conflicts when deploying multiple ADOT collectors (e.g., prometheus and container-insights) in the same namespace. The core ADOT configuration remains unchanged while only resource names are customizable via values.

### How Metrics are Discovered

This chart uses **annotation-based auto-discovery** for maximum flexibility. Any pod with the following annotations will be automatically scraped:

```yaml
annotations:
  prometheus.io/scrape: "true"   # Required: Enable scraping
  prometheus.io/port: "8080"     # Required: Port to scrape
  prometheus.io/path: "/metrics" # Optional: Metrics path (defaults to /metrics)
```

**Benefits:**
- ✅ **Scalable**: Add new services without modifying the ADOT collector configuration
- ✅ **Declarative**: Each service declares its own monitoring requirements
- ✅ **Flexible**: Different services can use different ports and paths

### Adding New Services to Monitoring

To monitor a new service, simply add annotations to its Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-new-service
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
        prometheus.io/path: "/metrics"
      labels:
        app: my-new-service  # This becomes the 'job' label in Prometheus
    spec:
      containers:
        - name: my-service
          ports:
            - containerPort: 9090
```

**No ConfigMap changes needed!** The ADOT collector will automatically discover and scrape the new service.

### Current Monitored Services

By default, this chart monitors all pods in the `{{ .Values.application.namespace }}` namespace with `prometheus.io/scrape: "true"` annotation.

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod -n aws-otel-eks -l app=adot-collector-prometheus
kubectl get events -n aws-otel-eks --sort-by='.lastTimestamp'
```

### IAM permission errors

```bash
# Verify service account annotation
kubectl get sa -n aws-otel-eks adot-collector-prometheus -o yaml

# Check role ARN
kubectl get sa -n aws-otel-eks adot-collector-prometheus -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
```

### Metrics not reaching AMP

```bash
# Check collector logs
kubectl logs -n aws-otel-eks -l app=adot-collector-prometheus --tail=100

# Verify AMP endpoint (use configured configMapName from values)
kubectl get configmap -n aws-otel-eks adot-collector-prometheus-config -o yaml
```

## Uninstall

```bash
helm uninstall adot-prometheus --namespace aws-otel-eks
```

## Related Documentation

- [AWS Distro for OpenTelemetry](https://aws-otel.github.io/)
- [Amazon Managed Prometheus](https://docs.aws.amazon.com/prometheus/)
- [ADOT Collector Configuration](https://aws-otel.github.io/docs/getting-started/collector)
