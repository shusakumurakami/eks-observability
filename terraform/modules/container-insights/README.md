# Observability Container Insights Module

This module manages Container Insights infrastructure for EKS, providing CloudWatch monitoring capabilities.

## Purpose

- Provides IRSA (IAM Roles for Service Accounts) for Container Insights collector
- Sets up IAM policies for CloudWatch Logs and Metrics
- **Does not include**: Amazon Managed Prometheus (AMP) or Grafana

## What it creates

1. **IRSA for Container Insights**: IAM role for `adot-collector-container-insights` service account
2. **IAM Policy**: Permissions for CloudWatch Logs (`/aws/containerinsights/*`) and Metrics (`ContainerInsights` namespace)

## Usage

```hcl
module "observability_core" {
  source = "../../modules/container-insights"

  resource_name_prefix = "myapp-dev"
  region               = "ap-northeast-1"
  eks_cluster_name     = "myapp-dev-eks"
  environment          = "dev"
  oidc_provider_arn    = module.eks.oidc_provider_arn

  # Optional: Override defaults
  adot_collector_namespace            = "aws-otel-eks"
  container_insights_service_account  = "adot-collector-container-insights"
}
```

## Outputs

- `container_insights_role_arn`: IAM role ARN for Container Insights
- `container_insights_service_account`: Service account name
- `adot_collector_namespace`: Kubernetes namespace

## Related Helm Chart

Deploy the ADOT Container Insights collector using:
- Helm chart: `infra/helm/adot-container-insights`
- Uses the IAM role created by this module

## Notes

- This module is for **CloudWatch-only monitoring**
- For Prometheus metrics, use `managed-prometheus` module separately
- Container Insights metrics are sent to CloudWatch in EMF (Embedded Metric Format)
