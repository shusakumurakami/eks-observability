# EKS Observability

Comprehensive observability stack for Amazon EKS Fargate clusters using CloudWatch Container Insights, Amazon Managed Prometheus (AMP), and Amazon Managed Grafana (AMG).

## Features

- **Fargate-Native**: Optimized for serverless Kubernetes workloads
- **Three-Tier Observability**: Logging, Metrics, and Visualization
- **IRSA Security**: All AWS API access uses IAM Roles for Service Accounts
- **Modular Design**: Deploy only the components you need
- **Infrastructure as Code**: Fully automated with Terraform and Helm

## Architecture

### Logging Layer
- Fargate built-in Fluent Bit streams logs to CloudWatch Logs
- Namespace-based retention policies (infrastructure: 7d, application: 30d, monitoring: 7d)

### Metrics Layer
- **Container Insights**: ADOT collector sends Fargate pod metrics to CloudWatch
- **Prometheus** (optional): ADOT collector sends application metrics to Amazon Managed Prometheus

### Visualization Layer
- **Amazon Managed Grafana**: Unified dashboards for CloudWatch and Prometheus metrics

## Repository Structure

```
.
├── terraform/
│   └── modules/
│       ├── eks/                    # EKS cluster with Fargate profiles
│       ├── container-insights/     # CloudWatch Container Insights IRSA
│       ├── managed-prometheus/     # Amazon Managed Prometheus workspace
│       └── managed-grafana/        # Amazon Managed Grafana workspace
└── helm/
    ├── fargate-logging/           # Fluent Bit logging configuration
    ├── adot-container-insights/   # ADOT collector for CloudWatch metrics
    └── adot-prometheus/           # ADOT collector for Prometheus metrics
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Helm >= 3.0
- kubectl

## Quick Start

### 1. Deploy Infrastructure

```bash
cd terraform/envs/dev

# Initialize Terraform
terraform init

# Deploy EKS cluster
terraform apply -target=module.eks

# Deploy observability components
terraform apply
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

### 3. Deploy Helm Charts

```bash
cd helm

# Install logging configuration
helm install fargate-logging ./fargate-logging \
  -f ./fargate-logging/values/values-dev.yaml \
  --namespace aws-observability --create-namespace

# Install Container Insights
helm install adot-container-insights ./adot-container-insights \
  -f ./adot-container-insights/values/values-dev.yaml \
  --namespace aws-otel-eks --create-namespace

# (Optional) Install Prometheus collector
helm install adot-prometheus ./adot-prometheus \
  -f ./adot-prometheus/values/values-dev.yaml \
  --namespace aws-otel-eks \
  --set namespace.create=false
```

## Module Dependencies

```
eks (base)
├── container-insights (CloudWatch-only monitoring)
├── managed-prometheus (optional: Prometheus metrics)
└── managed-grafana (optional: visualization)
```

The `eks` module must be deployed first. Other modules can be deployed independently based on your requirements.

## Configuration

### Terraform Modules

All modules accept these common variables:
- `resource_name_prefix`: Prefix for resource naming
- `region`: AWS region
- `environment`: Environment name (dev/staging/prod)
- `oidc_provider_arn`: EKS OIDC provider ARN (not required for eks module)

Example:
```hcl
module "eks" {
  source = "../../modules/eks"

  resource_name_prefix = "myapp"
  region              = "us-west-2"
  environment         = "dev"
  application_name    = "myapp"
}
```

### Helm Charts

Environment-specific values files are located in `helm/<chart-name>/values/values-<env>.yaml`.

Key configurations:
- **fargate-logging**: Log group names and retention periods
- **adot-container-insights**: IRSA role ARN and cluster name
- **adot-prometheus**: AMP workspace endpoint and IRSA role ARN

## Monitoring Your Applications

### Adding Prometheus Metrics

Simply add annotations to your pod template:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
```

The ADOT collector will automatically discover and scrape annotated pods.

## Accessing Dashboards

### CloudWatch Container Insights
1. Navigate to CloudWatch console
2. Select "Container Insights" from the left menu
3. Choose your EKS cluster

### Amazon Managed Grafana
1. Navigate to Amazon Managed Grafana console
2. Access your workspace URL
3. Sign in with AWS SSO or SAML

Data sources (CloudWatch and AMP) are automatically configured via IAM roles.

## Cost Estimate

Monthly costs for a dev environment:

| Component | Cost |
|-----------|------|
| EKS cluster | ~$73 |
| Fargate compute | ~$50-100 |
| CloudWatch Logs | ~$5-20 |
| Amazon Managed Prometheus (optional) | Variable |
| Amazon Managed Grafana (optional) | $9/editor, $5/viewer |

**Total**: ~$130-200/month (without Prometheus/Grafana)

## Troubleshooting

### Pods Stuck in Pending
- Verify Fargate profile selectors match pod namespace
- Check Fargate profile status: `aws eks describe-fargate-profile`

### Logs Not Appearing
1. Verify ConfigMap: `kubectl get configmap -n aws-observability aws-logging`
2. Check Fargate execution role has CloudWatch Logs permissions
3. Restart pods after applying logging ConfigMap

### ADOT Collector Errors
1. Check logs: `kubectl logs -n aws-otel-eks <pod-name>`
2. Verify service account annotation: `kubectl get sa -n aws-otel-eks <sa-name> -o yaml`
3. Ensure IAM role trust policy allows OIDC provider

## Security

- **Deletion Protection**: Enabled on EKS cluster by default
- **IRSA**: No long-lived AWS credentials in pods
- **Least Privilege**: IAM policies scoped to specific resources
- **Authentication**: Grafana requires AWS SSO or SAML

## Documentation

For detailed information about architecture decisions and troubleshooting, see [CLAUDE.md](./CLAUDE.md).
