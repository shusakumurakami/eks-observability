# Fargate Logging Helm Chart

AWS Fargate logging configuration for EKS using Fluent Bit. This chart configures cluster-wide logging for all Fargate pods with namespace-based log group separation.

## Overview

This Helm chart deploys the `aws-observability` namespace and ConfigMap to configure Fargate's built-in Fluent Bit log router. Logs are separated into different CloudWatch Log Groups based on namespace and purpose:

- **Infrastructure logs**: System components (default, kube-system, external-secrets)
- **Application logs**: Application workloads (myapp)
- **Monitoring logs**: Observability infrastructure (aws-otel-eks, aws-observability)

## Architecture

```
┌─────────────────────┐
│ Fargate Pods        │
│ (All namespaces)    │
└──────────┬──────────┘
           │ stdout/stderr
           ▼
┌─────────────────────┐
│ Fluent Bit          │
│ (Built into Fargate)│
└──────────┬──────────┘
           │ Configured via aws-observability ConfigMap
           │
           ├─────────────────────────────────────────────┐
           │                                             │
           ▼                                             ▼
┌──────────────────────────┐                 ┌──────────────────────────┐
│ CloudWatch Logs          │                 │ CloudWatch Logs          │
│ /infrastructure/default  │    ...          │ /application/myapp       │
│ Retention: 7 days        │                 │ Retention: 30 days       │
└──────────────────────────┘                 └──────────────────────────┘
```

## Prerequisites

1. EKS cluster with Fargate profiles configured
2. **Terraform applied**: Log groups and IAM policies must be created first
   ```bash
   cd infra/terraform/envs/dev/main
   terraform apply
   ```
3. Helm 3.x installed
4. kubectl configured to access your EKS cluster

## Installation

### Step 1: Create environment-specific values file

Create `values/values-dev.yaml`:

```yaml
global:
  clusterName: myapp-dev-eks
  environment: development
  aws:
    region: ap-northeast-1

logging:
  fluentBitLogsEnabled: false
  defaultRetentionDays: 7

  namespaces:
    infrastructure:
      - name: default
        retentionDays: 7
      - name: kube-system
        retentionDays: 7
      - name: external-secrets
        retentionDays: 7

    application:
      - name: myapp
        retentionDays: 30

    monitoring:
      - name: aws-otel-eks
        retentionDays: 7
      - name: aws-observability
        retentionDays: 7
```

### Step 2: Install the chart

```bash
cd infra/helm

# Install
helm install fargate-logging ./fargate-logging \
  -f ./fargate-logging/values/values-dev.yaml

# Upgrade (after initial install)
helm upgrade fargate-logging ./fargate-logging \
  -f ./fargate-logging/values/values-dev.yaml
```

### Step 3: Verify installation

```bash
# Check namespace
kubectl get namespace aws-observability

# Check ConfigMap
kubectl get configmap -n aws-observability aws-logging

# View ConfigMap content
kubectl describe configmap -n aws-observability aws-logging
```

### Step 4: Restart existing pods (Important!)

**Important**: Fargate logging configuration only applies to new pods. Existing pods must be restarted:

```bash
# Restart application pods
kubectl rollout restart deployment -n myapp

# Restart system pods (if needed)
kubectl rollout restart deployment -n kube-system
```

## Configuration

### Log Group Structure

Logs are organized by namespace and purpose:

```
/aws/eks/{cluster-name}/
├── infrastructure/
│   ├── default/
│   ├── kube-system/
│   └── external-secrets/
├── application/
│   └── myapp/
└── monitoring/
    ├── aws-otel-eks/
    └── aws-observability/
```

### Retention Periods

- **Infrastructure logs**: 7 days (default)
- **Application logs**: 30 days (customizable per namespace)
- **Monitoring logs**: 7 days (default)

### Customization

Edit `values.yaml` or create environment-specific values files:

```yaml
logging:
  # Enable Fluent Bit process logs (for debugging)
  fluentBitLogsEnabled: false

  # Default retention for all namespaces
  defaultRetentionDays: 7

  # Add new namespaces
  namespaces:
    application:
      - name: my-new-app
        retentionDays: 60
```

## Viewing Logs

### CloudWatch Logs Console

1. Navigate to CloudWatch → Log groups
2. Filter by `/aws/eks/{cluster-name}/`
3. Select the appropriate log group for your namespace

### CloudWatch Logs Insights

```bash
# Example query for application logs
fields @timestamp, @message
| filter kubernetes.namespace_name = "myapp"
| sort @timestamp desc
| limit 100
```

### kubectl logs (still works)

```bash
kubectl logs -n myapp <pod-name>
```

## Troubleshooting

### Logs not appearing in CloudWatch

1. **Check if ConfigMap is applied**:
   ```bash
   kubectl get configmap -n aws-observability aws-logging -o yaml
   ```

2. **Verify IAM permissions**: Fargate execution role needs CloudWatch Logs permissions (configured in Terraform)

3. **Restart pods**: ConfigMap changes only apply to new pods
   ```bash
   kubectl rollout restart deployment -n <namespace>
   ```

4. **Check Fluent Bit logs** (if enabled):
   ```bash
   # Enable in values.yaml: fluentBitLogsEnabled: true
   # Then check CloudWatch Logs for fluent-bit logs
   ```

### ConfigMap validation errors

If you see errors when applying the chart, validate the ConfigMap:

- Maximum size: 5300 characters
- Only FILTER, OUTPUT, and PARSER sections allowed (no INPUT or SERVICE)
- Each OUTPUT must have valid `Name` and `Match` fields

### Logs in wrong log group

Check the `Match` pattern in the ConfigMap. The pattern matches against Kubernetes metadata:

- `*myapp*` matches pods in the myapp namespace
- `*kube-system*` matches pods in kube-system namespace

## Uninstall

```bash
helm uninstall fargate-logging
```

**Note**: This will remove the ConfigMap, but CloudWatch Log Groups created by Terraform will remain. To remove log groups, use Terraform:

```bash
cd infra/terraform/envs/dev/main
terraform destroy -target=aws_cloudwatch_log_group.fargate_application_myapp
```

## Relationship with Other Charts

This chart is independent from application and monitoring charts:

- **fargate-logging**: Cluster-wide logging configuration
- **adot-container-insights**: Container metrics to CloudWatch
- **adot-prometheus**: Application metrics to Amazon Managed Prometheus
- **myapp**: Application deployment

Install order:
1. fargate-logging (cluster-wide logging)
2. adot-* charts (monitoring infrastructure)
3. myapp (application)

## Reference Links

- [AWS Fargate Logging](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html)
- [Fluent Bit Configuration](https://docs.fluentbit.io/manual/)
- [CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
