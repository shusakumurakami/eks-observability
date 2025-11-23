# Observability Grafana Module

Terraform module for managing Amazon Managed Grafana (AMG) workspace with access to CloudWatch and Amazon Managed Prometheus data sources.

## Features

- Amazon Managed Grafana workspace with flexible authentication (AWS SSO or SAML)
- IAM roles and policies for CloudWatch and AMP access
- Automatic data source discovery via IAM permissions
- Optional module - only deploy if you need Grafana for visualization

## Prerequisites

- **For AWS SSO authentication**: AWS IAM Identity Center must be enabled
- **For SAML authentication**: External SAML 2.0 IdP configured
- **For AMP data source**: Deploy `managed-prometheus` module (optional)
- Appropriate IAM permissions to create Grafana resources

## Usage

### Basic usage (CloudWatch only)

```hcl
module "grafana" {
  source = "../../modules/managed-grafana"

  resource_name_prefix     = "myapp-dev"
  region                   = "ap-northeast-1"
  environment              = "dev"
  authentication_providers = ["AWS_SSO"]
}
```

### With Amazon Managed Prometheus

Deploy `managed-prometheus` module first, then Grafana will automatically discover AMP via IAM permissions:

```hcl
# First, create AMP workspace
module "observability_prometheus" {
  source = "../../modules/managed-prometheus"
  # ...
}

# Grafana discovers AMP automatically via IAM
module "grafana" {
  source = "../../modules/managed-grafana"

  resource_name_prefix     = "myapp-dev"
  region                   = "ap-northeast-1"
  environment              = "dev"
  authentication_providers = ["AWS_SSO"]
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| resource_name_prefix | Prefix for resource names | string | yes | - |
| region | AWS region | string | yes | - |
| environment | Environment name (dev, staging, production) | string | yes | - |
| authentication_providers | List of auth providers (AWS_SSO, SAML) | list(string) | no | ["AWS_SSO"] |
| amp_workspace_id | AMP workspace ID (optional, not used) | string | no | "" |

## Outputs

| Name | Description |
|------|-------------|
| workspace_id | AMG workspace ID |
| workspace_endpoint | AMG workspace endpoint URL |
| workspace_arn | AMG workspace ARN |
| iam_role_arn | IAM role ARN for Grafana workspace |

## Resources Created

1. **Amazon Managed Grafana Workspace**
   - Permission type: CUSTOMER_MANAGED
   - Authentication: AWS SSO or SAML
   - Data sources: CloudWatch, Prometheus
   - Notification destinations: SNS

2. **IAM Role for Grafana** (`grafana-service-role`)
   - CloudWatch read access (metrics, alarms, logs)
   - CloudWatch Logs query access
   - AMP query access (list, describe, query metrics)
   - EC2 describe permissions for resource tagging

3. **IAM Policies**
   - CloudWatch access policy
   - AMP access policy
   - Automatic policy attachments with IAM propagation delay

## Post-Deployment Steps

1. **Setup AWS SSO Users**
   ```bash
   # Assign users to Grafana workspace in AWS SSO
   ```

2. **Access Grafana**
   ```bash
   # Get workspace endpoint
   terraform output grafana_workspace_endpoint

   # Open in browser and sign in with AWS SSO
   ```

3. **Verify Data Sources**
   - Go to Configuration > Data Sources
   - Check that Prometheus and CloudWatch are configured
   - Test connections

## Cost Estimation

Amazon Managed Grafana pricing:
- Editor license: $9/user/month
- Viewer license: $5/user/month
- First 10GB of dashboard and data source storage: Free

Estimated cost for dev environment:
- 1-2 editor users: $9-18/month
- 0-5 viewer users: $0-25/month
- **Total: ~$10-45/month**

## Security Considerations

- AWS SSO authentication required
- IAM roles follow least privilege principle
- Service account tokens are marked sensitive
- Data sources use workspace IAM roles (no credentials in Grafana)

## Troubleshooting

### Issue: Cannot access Grafana workspace
**Solution**: Ensure AWS SSO is configured and users are assigned to the workspace

### Issue: Data sources not working
**Solution**: Verify IAM role has correct permissions and is attached to workspace

### Issue: Prometheus queries fail
**Solution**: Check AMP workspace ID is correct and IAM policy allows aps:QueryMetrics
