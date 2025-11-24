# Dev Environment Configuration

This directory contains example configurations for the development environment.

## File Structure

```
dev/
├── provider.tf.example    # Provider configuration with default_tags
├── main.tf.example        # Main infrastructure configuration
└── README.md             # This file
```

## Usage

### 1. Copy Example Files

```bash
cp provider.tf.example provider.tf
cp main.tf.example main.tf
```

### 2. Update Configuration

Edit `main.tf` and replace placeholder values:

- `vpc_id`: Your VPC ID
- `private_subnet_ids`: Your private subnet IDs
- Any other environment-specific values

Edit `provider.tf` to customize default tags if needed.

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan and Apply

```bash
# Review changes
terraform plan

# Apply changes
terraform apply
```

## Default Tags

Tags are managed via `default_tags` in the provider configuration. All resources created by the modules will automatically inherit these tags:

```hcl
default_tags {
  tags = {
    Environment = "dev"
    Project     = "eks-observability"
    ManagedBy   = "Terraform"
    Repository  = "eks-observability"
    Owner       = "platform-team"
  }
}
```

This approach:
- Ensures consistent tagging across all resources
- Eliminates the need to explicitly tag each resource
- Simplifies module code by not requiring tag parameters
- Allows easy customization per environment

## Module Dependencies

```
eks (base)
├── container-insights
├── managed-prometheus
└── managed-grafana (depends on prometheus)
```

Apply modules in order, or let Terraform handle dependencies automatically.

## Outputs

After applying, you can view outputs:

```bash
# View all outputs
terraform output

# View specific output
terraform output -raw container_insights_role_arn
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: EKS clusters have deletion protection enabled by default. Disable it in the console before destroying if needed.
