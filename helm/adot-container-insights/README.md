# ADOT Container Insights Collector Helm Chart

AWS Distro for OpenTelemetry (ADOT) Collector for Container Insights on EKS Fargate, sending metrics to Amazon CloudWatch.

## Overview

This Helm chart deploys an ADOT Collector configured to:
- Collect Container Insights metrics from EKS Fargate pods
- Send metrics to Amazon CloudWatch via EMF (Embedded Metric Format)
- Use AWS official configuration with minimal customization
- Use IRSA (IAM Roles for Service Accounts) for AWS authentication

**Based on**: [AWS Official Container Insights for EKS Fargate](https://github.com/aws-observability/aws-otel-collector/blob/main/deployment-template/eks/otel-fargate-container-insights.yaml)

## Prerequisites

1. EKS Fargate cluster with IRSA configured
2. **Terraform module deployed**: `container-insights` module creates the IAM role
3. Helm 3.x installed
4. kubectl configured to access your EKS cluster

## Installation

### Step 1: Get Terraform outputs

```bash
cd terraform/envs/dev/

export CONTAINER_INSIGHTS_ROLE_ARN=$(terraform output -raw container_insights_role_arn)
```

### Step 2: Install the chart

**Note**: By default, the chart will create the `aws-otel-eks` namespace (controlled by `namespace.create: true` in values.yaml). If you're also deploying the `adot-prometheus` chart, set `namespace.create: false` to avoid conflicts.

```bash
# Install Container Insights (namespace will be created automatically)
helm install adot-container-insights ./adot-container-insights \
  -f ./adot-container-insights/values/values-dev.yaml \
  --namespace aws-otel-eks

# Upgrade (after initial install)
helm upgrade adot-container-insights ./adot-container-insights \
  -f ./adot-container-insights/values/values-dev.yaml \
  --namespace aws-otel-eks

# If adot-prometheus is also deployed, install with namespace creation disabled:
# helm install adot-container-insights ./adot-container-insights \
#   -f ./adot-container-insights/values/values-dev.yaml \
#   --set namespace.create=false \
#   --namespace aws-otel-eks
```

### Step 3: Verify deployment

```bash
# Check pods
kubectl get pods -n aws-otel-eks -l component=adot-collector-container-insights

# Check logs
kubectl logs -n aws-otel-eks -l component=adot-collector-container-insights --tail=50
```

## Configuration

### Values

Key configuration values in `values.yaml`:

```yaml
aws:
  region: ap-northeast-1
  clusterName: "your-cluster-name"

serviceAccount:
  name: adot-collector-container-insights
  roleArn: "arn:aws:iam::xxx:role/container-insights-irsa"

namespace:
  name: aws-otel-eks
  create: true  # Set to false if adot-prometheus chart creates the namespace

# Resource naming (customized to avoid conflicts with adot-prometheus)
resources:
  configMapName: adot-collector-container-insights-config
  serviceName: adot-collector-container-insights-service
  containerName: adot-collector-container-insights
  componentLabel: adot-collector-container-insights
```

### AWS Official Configuration

This chart uses the **official AWS ADOT Collector configuration** with only necessary template variables:
- `{{ .Values.aws.region }}` - AWS region
- `{{ .Values.aws.clusterName }}` - EKS cluster name
- `{{ .Values.serviceAccount.roleArn }}` - IAM role ARN for IRSA
- `{{ .Values.namespace.name }}` - Kubernetes namespace
- `{{ .Values.resources.* }}` - Resource naming (customized to avoid conflicts with adot-prometheus)

The core ADOT configuration remains unchanged from AWS official template. Only resource names and labels are customizable via values to support multi-collector deployments.

## Viewing Metrics in CloudWatch

Metrics are sent to CloudWatch Logs in EMF format:
- **Log Group**: `/aws/containerinsights/{ClusterName}/performance`
- **Namespace**: `ContainerInsights`

Available metrics include:
- `pod_cpu_utilization_over_pod_limit`
- `pod_cpu_usage_total`
- `pod_memory_utilization_over_pod_limit`
- `pod_memory_working_set`
- `pod_network_rx_bytes` / `pod_network_tx_bytes`

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod -n aws-otel-eks -l component=adot-collector-container-insights
kubectl get events -n aws-otel-eks --sort-by='.lastTimestamp'
```

### IAM permission errors

```bash
# Verify service account annotation
kubectl get sa -n aws-otel-eks adot-collector-container-insights -o yaml

# Check role ARN
kubectl get sa -n aws-otel-eks adot-collector-container-insights \
  -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
```

### Metrics not reaching CloudWatch

```bash
# Check collector logs
kubectl logs -n aws-otel-eks -l component=adot-collector-container-insights --tail=100

# Verify cluster name environment variable
kubectl get statefulset -n aws-otel-eks adot-collector-container-insights -o yaml | grep OTEL_RESOURCE_ATTRIBUTES
```

### No metrics in CloudWatch

1. Ensure your cluster has Fargate pods (Container Insights only monitors Fargate)
2. Check IAM role permissions for CloudWatch Logs write access
3. Verify log group exists: `/aws/containerinsights/{ClusterName}/performance`

## Uninstall

```bash
helm uninstall adot-container-insights --namespace aws-otel-eks
```

## Architecture

```
┌─────────────────┐
│ EKS Fargate Pod │
│   (Workload)    │
└────────┬────────┘
         │ kubelet metrics (cAdvisor)
         ▼
┌─────────────────────┐
│ Kubernetes API      │
│   /metrics/cadvisor │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ ADOT Collector      │
│ (StatefulSet)       │
│ - Prometheus rcvr   │
│ - Metric transforms │
│ - EMF exporter      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ CloudWatch Logs     │
│ (EMF format)        │
└─────────────────────┘
```

## Related Documentation

- [AWS Official Configuration](https://github.com/aws-observability/aws-otel-collector/blob/main/deployment-template/eks/otel-fargate-container-insights.yaml)
- [Container Insights for EKS Fargate](https://aws.amazon.com/blogs/containers/introducing-amazon-cloudwatch-container-insights-for-amazon-eks-fargate-using-aws-distro-for-opentelemetry/)
- [AWS Distro for OpenTelemetry](https://aws-otel.github.io/)
- [CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)
