# EKS Cluster Module

Terraform module for managing Amazon EKS cluster with Fargate profiles and CloudWatch logging integration.

## Features

- Amazon EKS cluster with configurable Kubernetes version
- Multiple Fargate profiles for workload separation (infrastructure, application, monitoring)
- IRSA (IAM Roles for Service Accounts) enabled
- CloudWatch logging for control plane and Fargate pods
- Custom IAM policies following least privilege principle
- VPC-CNI, CoreDNS, and kube-proxy add-ons
- Deletion protection enabled by default

## What it creates

1. **EKS Cluster**
   - Kubernetes control plane with specified version
   - Public and private API endpoint access
   - CloudWatch control plane logging (API, audit, authenticator, controller manager, scheduler)
   - IRSA (IAM Roles for Service Accounts) support

2. **Fargate Profiles**
   - **Infrastructure profile**: `default`, `kube-system`, `external-secrets` namespaces
   - **Application profile**: Custom application namespace
   - **Monitoring profile**: `aws-otel-eks`, `aws-observability` namespaces

3. **IAM Policies and Roles**
   - Fargate pod execution roles with CloudWatch logging permissions
   - Custom IAM policy for Fargate logging with least privilege

4. **CloudWatch Log Groups**
   - Separate log groups per namespace for better organization
   - Configurable retention periods (7 days for infrastructure/monitoring, 30 days for application)

## Prerequisites

- VPC with private subnets
- Security groups for EKS cluster and pods
- Appropriate IAM permissions to create EKS resources

## Usage

### Basic usage

```hcl
module "eks" {
  source = "../../modules/eks"

  eks_cluster_name                = "myapp-dev-eks"
  resource_name_prefix            = "myapp-dev"
  region                          = "ap-northeast-1"
  vpc_id                          = module.vpc.vpc_id
  private_subnets                 = module.vpc.private_subnets
  eks_cluster_security_group_id   = aws_security_group.eks_cluster.id
  application_name                = "myapp"

  # Optional: Override defaults
  kubernetes_version              = "1.31"
  endpoint_public_access_cidrs    = ["203.0.113.0/24"]
  eks_pods_security_group_ids     = [aws_security_group.eks_pods.id]
}
```

### With custom Kubernetes version

```hcl
module "eks" {
  source = "../../modules/eks"

  eks_cluster_name                = "myapp-prod-eks"
  resource_name_prefix            = "myapp-prod"
  region                          = "ap-northeast-1"
  vpc_id                          = module.vpc.vpc_id
  private_subnets                 = module.vpc.private_subnets
  eks_cluster_security_group_id   = aws_security_group.eks_cluster.id
  application_name                = "myapp"
  kubernetes_version              = "1.30"
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| eks_cluster_name | Name of the EKS cluster | string | yes | - |
| resource_name_prefix | Prefix for resource names | string | yes | - |
| region | AWS region | string | yes | - |
| vpc_id | VPC ID where EKS cluster will be deployed | string | yes | - |
| private_subnets | List of private subnet IDs for EKS cluster and Fargate profiles | list(string) | yes | - |
| eks_cluster_security_group_id | Security group ID for EKS cluster | string | yes | - |
| application_name | Name of the application for Fargate profile namespace | string | yes | - |
| kubernetes_version | Kubernetes version for EKS cluster | string | no | "1.31" |
| endpoint_public_access_cidrs | List of CIDR blocks that can access the EKS cluster endpoint publicly | list(string) | no | ["0.0.0.0/0"] |
| eks_pods_security_group_ids | Additional security group IDs for EKS pods | list(string) | no | [] |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID/name of the EKS cluster |
| cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| cluster_endpoint | Endpoint for EKS control plane |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_certificate_authority_data | Base64 encoded certificate data (sensitive) |
| cluster_version | The Kubernetes server version for the cluster |
| cluster_platform_version | The platform version for the cluster |
| cluster_status | Status of the EKS cluster |
| oidc_provider_arn | ARN of the OIDC Provider for EKS |
| oidc_provider | The OpenID Connect identity provider |
| fargate_profiles | Map of Fargate Profile attributes |
| fargate_log_groups | Map of CloudWatch log groups for Fargate profiles |
| fargate_logging_policy_arn | ARN of the IAM policy for Fargate logging |

## Resources Created

1. **Amazon EKS Cluster** (via terraform-aws-modules/eks/aws)
   - Control plane with specified Kubernetes version
   - VPC and subnet configuration
   - Security group configuration
   - CloudWatch logging enabled

2. **EKS Add-ons**
   - CoreDNS (configured for Fargate)
   - kube-proxy
   - vpc-cni

3. **Fargate Profiles**
   - Infrastructure profile for system namespaces
   - Application profile for application workloads
   - Monitoring profile for observability tools

4. **IAM Resources**
   - Custom IAM policy for Fargate pod logging
   - Fargate pod execution roles (managed by EKS module)

5. **CloudWatch Log Groups**
   - `/aws/eks/{cluster_name}/infrastructure/default`
   - `/aws/eks/{cluster_name}/infrastructure/kube-system`
   - `/aws/eks/{cluster_name}/infrastructure/external-secrets`
   - `/aws/eks/{cluster_name}/application/{app_name}`
   - `/aws/eks/{cluster_name}/monitoring/aws-otel-eks`
   - `/aws/eks/{cluster_name}/monitoring/aws-observability`

## Post-Deployment Steps

1. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --name <cluster_name> --region <region>
   ```

2. **Verify cluster access**
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

3. **Deploy Fargate logging configuration**
   ```bash
   # Deploy ConfigMap for Fargate logging
   kubectl apply -f fargate-logging-configmap.yaml
   ```

## Fargate Profile Configuration

### Infrastructure Profile
- **Namespaces**: `default`, `kube-system`, `external-secrets`
- **Use case**: System components, secrets management
- **Log retention**: 7 days

### Application Profile
- **Namespaces**: Custom application namespace
- **Use case**: Application workloads
- **Log retention**: 30 days

### Monitoring Profile
- **Namespaces**: `aws-otel-eks`, `aws-observability`
- **Use case**: ADOT collectors, monitoring tools
- **Log retention**: 7 days

## Security Considerations

- Deletion protection enabled to prevent accidental cluster deletion
- Custom security groups for cluster and pods
- IRSA enabled for secure AWS API access from pods
- IAM policies follow least privilege principle
- Public endpoint access can be restricted via CIDR blocks
- CloudWatch logging enabled for audit and compliance

## Cost Estimation

Amazon EKS pricing:
- EKS cluster: $0.10/hour (~$73/month)
- Fargate pod compute: Based on vCPU and memory usage
- CloudWatch Logs: Based on log ingestion and storage

Estimated cost for dev environment:
- EKS cluster: ~$73/month
- Fargate compute (3-5 small pods): ~$50-100/month
- CloudWatch Logs: ~$5-20/month
- **Total: ~$130-200/month**

## Troubleshooting

### Issue: Pods stuck in Pending state
**Solution**: Verify Fargate profile selectors match pod namespace and labels

### Issue: Cannot access cluster endpoint
**Solution**: Check `endpoint_public_access_cidrs` includes your IP address

### Issue: Fargate pods cannot write logs to CloudWatch
**Solution**: Verify IAM policy is attached to Fargate pod execution role and log groups exist

### Issue: CoreDNS pods not running
**Solution**: Ensure CoreDNS add-on is configured with `computeType = "Fargate"`

## Related Resources

- [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [EKS Fargate Documentation](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html)
- [IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
