# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository provides infrastructure as code (Terraform) and deployment configurations (Helm) for setting up comprehensive observability on Amazon EKS Fargate clusters. It integrates CloudWatch Container Insights, Amazon Managed Prometheus (AMP), and Amazon Managed Grafana (AMG) for monitoring and logging.

## Project Structure

```
.
├── terraform/          # Infrastructure as Code
│   └── modules/        # Reusable Terraform modules
│       ├── eks/                    # EKS cluster with Fargate profiles
│       ├── container-insights/     # CloudWatch Container Insights (IRSA only)
│       ├── managed-prometheus/     # Amazon Managed Prometheus workspace
│       └── managed-grafana/        # Amazon Managed Grafana workspace
└── helm/              # Kubernetes workload deployments
    ├── fargate-logging/           # Fluent Bit logging configuration
    ├── adot-container-insights/   # ADOT collector for CloudWatch metrics
    └── adot-prometheus/           # ADOT collector for Prometheus metrics
```

## Architecture Overview

### Three-Tier Observability Stack

1. **Logging Layer**: Fargate built-in Fluent Bit sends logs to CloudWatch Logs
   - Configured via `fargate-logging` Helm chart (deploys ConfigMap to `aws-observability` namespace)
   - Logs organized by namespace: infrastructure (7d), application (30d), monitoring (7d)

2. **Metrics Layer**: ADOT collectors scrape and send metrics
   - **Container Insights**: Fargate pod metrics → CloudWatch (EMF format)
   - **Prometheus**: Application metrics → Amazon Managed Prometheus

3. **Visualization Layer**: Amazon Managed Grafana
   - Queries CloudWatch and AMP via IAM roles (no credentials)
   - Requires AWS SSO or SAML authentication

### Key Design Decisions

- **Fargate-only**: No EC2 node groups, all workloads run on Fargate
- **IRSA everywhere**: All AWS API access uses IAM Roles for Service Accounts
- **Namespace-based separation**: Fargate profiles segregate infrastructure, application, and monitoring workloads
- **Optional Prometheus/Grafana**: Container Insights works standalone; AMP/Grafana modules are optional

### Fargate Profile Configuration

The EKS module creates three Fargate profiles:

- **infrastructure**: `default`, `kube-system`, `external-secrets` namespaces
- **application**: Custom application namespace (configurable via `application_name` variable)
- **monitoring**: `aws-otel-eks`, `aws-observability` namespaces

## Terraform Development

### Module Dependencies

```
eks (base)
├── container-insights (CloudWatch-only monitoring)
├── managed-prometheus (optional: Prometheus metrics)
└── managed-grafana (optional: visualization)
    └── requires: managed-prometheus (if using Prometheus data)
```

### Common Terraform Commands

```bash
# Navigate to environment directory first
cd terraform/envs/<env>/

# Initialize and validate
terraform init
terraform validate
terraform fmt -recursive

# Plan and apply
terraform plan
terraform apply

# Get outputs (used by Helm charts)
terraform output -raw container_insights_role_arn
terraform output -raw prometheus_workspace_endpoint
terraform output -raw prometheus_adot_collector_role_arn
terraform output -raw grafana_workspace_endpoint
```

### Module Usage Patterns

All Terraform modules follow consistent patterns:

- **Required inputs**: `resource_name_prefix`, `region`, `environment`, `oidc_provider_arn` (except eks module)
- **IRSA outputs**: Each module outputs IAM role ARN, service account name, and namespace
- **Least privilege IAM**: Custom IAM policies scoped to specific resources

### Important Module Notes

- **eks module**: Must be applied first; creates cluster, Fargate profiles, CloudWatch log groups, and Fargate logging IAM policy
- **container-insights module**: Only creates IRSA for CloudWatch; no AMP/Grafana resources
- **managed-prometheus module**: Optional; only needed if you want Prometheus metrics or Grafana
- **managed-grafana module**: IAM role has permissions for both CloudWatch and AMP; automatically discovers data sources

## Helm Development

### Deployment Order

1. **fargate-logging** (cluster-wide logging configuration)
2. **adot-container-insights** and/or **adot-prometheus** (monitoring infrastructure)
3. Application workloads

### Common Helm Commands

```bash
# Navigate to helm directory
cd helm/

# Install with environment-specific values
helm install <release-name> ./<chart-name> \
  -f ./<chart-name>/values/values-<env>.yaml \
  --namespace <namespace>

# Upgrade existing release
helm upgrade <release-name> ./<chart-name> \
  -f ./<chart-name>/values/values-<env>.yaml \
  --namespace <namespace>

# Verify deployment
kubectl get pods -n <namespace>
kubectl logs -n <namespace> <pod-name> --tail=50

# Uninstall
helm uninstall <release-name> --namespace <namespace>
```

### Chart-Specific Notes

#### fargate-logging

- Deploys ConfigMap to `aws-observability` namespace (not `aws-otel-eks`)
- **Important**: Restart existing pods after applying for configuration to take effect
- ConfigMap defines namespace-to-loggroup routing for Fargate's built-in Fluent Bit
- Terraform must create log groups first

#### adot-container-insights

- Deploys ADOT collector StatefulSet to `aws-otel-eks` namespace
- Uses AWS official configuration from [aws-otel-collector examples](https://github.com/aws-observability/aws-otel-collector)
- Sends metrics in EMF format to CloudWatch Logs: `/aws/containerinsights/{ClusterName}/performance`
- Metrics appear in CloudWatch under `ContainerInsights` namespace
- By default, creates `aws-otel-eks` namespace (set `namespace.create: false` if deploying both ADOT charts)

#### adot-prometheus

- Deploys ADOT collector Deployment to `aws-otel-eks` namespace
- Uses annotation-based service discovery: pods with `prometheus.io/scrape: "true"` are automatically scraped
- Sends metrics via remote write to Amazon Managed Prometheus
- Set `replicaCount: 1` to avoid duplicate scraping (default is 2)
- By default, creates `aws-otel-eks` namespace (set `namespace.create: false` if `adot-container-insights` already created it)

### Adding New Services to Prometheus Monitoring

No ConfigMap changes needed! Just add annotations to the pod template:

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

### Namespace Creation Coordination

Both `adot-container-insights` and `adot-prometheus` can create the `aws-otel-eks` namespace. If deploying both:

- First chart: Use default `namespace.create: true`
- Second chart: Set `namespace.create: false` or use `--set namespace.create=false`

## Post-Deployment Verification

### After Terraform Apply

```bash
# Configure kubectl
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Verify cluster
kubectl get nodes  # Should show "No resources found" (Fargate has no nodes)
kubectl get pods -A
```

### After Helm Install

```bash
# fargate-logging
kubectl get configmap -n aws-observability aws-logging
kubectl rollout restart deployment -n <app-namespace>  # Apply logging to existing pods

# adot-container-insights
kubectl get pods -n aws-otel-eks -l component=adot-collector-container-insights
# Check CloudWatch Logs: /aws/containerinsights/{ClusterName}/performance
# Check CloudWatch Metrics: ContainerInsights namespace

# adot-prometheus
kubectl get pods -n aws-otel-eks -l app=adot-collector-prometheus
# Check AMP workspace in console for ingested metrics
```

## Troubleshooting Common Issues

### Pods Stuck in Pending

- Verify Fargate profile selectors match pod namespace
- Check Fargate profile status: `aws eks describe-fargate-profile`

### Logs Not Appearing in CloudWatch

1. Verify ConfigMap exists: `kubectl get configmap -n aws-observability aws-logging`
2. Check Fargate execution role has CloudWatch Logs permissions (created by Terraform)
3. Restart pods after applying logging ConfigMap

### ADOT Collector Permission Errors

1. Verify service account annotation: `kubectl get sa -n aws-otel-eks <sa-name> -o yaml`
2. Check IAM role trust policy allows OIDC provider
3. Ensure IAM role has correct permissions for CloudWatch/AMP

### Metrics Not in CloudWatch/AMP

1. Check ADOT collector logs: `kubectl logs -n aws-otel-eks <pod-name>`
2. Verify cluster name matches in Helm values and Terraform
3. For Prometheus: Check AMP workspace endpoint in values file matches Terraform output

## Cost Considerations

- **EKS cluster**: ~$73/month (fixed)
- **Fargate compute**: Based on vCPU/memory usage (~$50-100/month for dev)
- **CloudWatch Logs**: Based on ingestion and storage (~$5-20/month)
- **Amazon Managed Prometheus**: Based on metrics ingested (optional)
- **Amazon Managed Grafana**: $9/editor/month, $5/viewer/month (optional)

**Total dev environment**: ~$130-200/month without Prometheus/Grafana

## Key Configuration Files

- `terraform/modules/*/variables.tf` - Module input definitions
- `terraform/modules/*/outputs.tf` - Module outputs used by Helm charts
- `helm/*/values.yaml` - Chart defaults (not committed with environment-specific values)
- `helm/*/values/values-dev.yaml` - Environment-specific overrides
- `helm/*/templates/*.yaml` - Kubernetes manifests with templating

## Security Notes

- **Deletion protection**: Enabled on EKS cluster by default (prevents accidental deletion)
- **IRSA**: All AWS API access uses IAM roles, no long-lived credentials
- **Least privilege IAM**: All IAM policies scoped to specific log groups/workspaces
- **Public endpoint**: EKS API endpoint publicly accessible by default; restrict via `endpoint_public_access_cidrs`
- **Grafana authentication**: Requires AWS SSO or SAML; no anonymous access
