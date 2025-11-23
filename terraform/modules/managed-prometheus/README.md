# Observability Managed Prometheus Module

This module manages Amazon Managed Prometheus (AMP) infrastructure for EKS, including the AMP workspace and ADOT Prometheus collector.

## Purpose

- Provides Amazon Managed Prometheus (AMP) workspace for storing Prometheus metrics
- Sets up IRSA (IAM Roles for Service Accounts) for ADOT Prometheus collector
- Configures IAM policies for AMP remote write access
- **Use this module only if**: You need Prometheus metrics storage and/or Grafana visualization

## What it creates

1. **AMP Workspace**: Amazon Managed Prometheus workspace for metric storage
2. **IRSA for Prometheus Collector**: IAM role for `adot-collector-prometheus` service account
3. **IAM Policy**: Permissions for AMP remote write, query, and metadata operations

## Usage

```hcl
module "prometheus" {
  source = "../../modules/managed-prometheus"

  resource_name_prefix = "myapp-dev"
  environment          = "dev"
  oidc_provider_arn    = module.eks.oidc_provider_arn

  # Optional: Override defaults
  adot_collector_namespace       = "aws-otel-eks"
  adot_collector_service_account = "adot-collector-prometheus"
}
```

## Outputs

- `workspace_id`: AMP workspace ID
- `workspace_arn`: AMP workspace ARN
- `workspace_endpoint`: AMP remote write endpoint URL
- `adot_collector_role_arn`: IAM role ARN for ADOT Collector
- `adot_collector_service_account`: Service account name
- `adot_collector_namespace`: Kubernetes namespace

## Related Helm Chart

Deploy the ADOT Prometheus collector using:
- Helm chart: `infra/helm/adot-prometheus`
- Uses the AMP workspace and IAM role created by this module

## Integration with Grafana

The AMP workspace can be used as a data source for Grafana:

```hcl
module "grafana" {
  source = "../../modules/managed-grafana"

  amp_workspace_id = module.prometheus.workspace_id
  # ... other config
}
```

## Notes

- **This module is optional**: Only deploy if you need Prometheus metrics and/or Grafana
- For CloudWatch-only monitoring, use `container-insights` module instead
- AMP charges are based on metrics ingested and stored
- The ADOT collector scrapes Prometheus metrics from application pods and sends them to AMP
