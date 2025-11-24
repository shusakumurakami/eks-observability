#--------------------------------------------------
# EKS Cluster Outputs
#--------------------------------------------------
output "cluster_id" {
  description = "The ID/name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = module.eks.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = module.eks.cluster_status
}

#--------------------------------------------------
# OIDC Provider Outputs
#--------------------------------------------------
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = module.eks.oidc_provider
}

#--------------------------------------------------
# Fargate Profile Outputs
#--------------------------------------------------
output "fargate_profiles" {
  description = "Map of Fargate Profile attributes"
  value       = module.eks.fargate_profiles
}

#--------------------------------------------------
# CloudWatch Log Group Outputs
#--------------------------------------------------
output "fargate_log_groups" {
  description = "Map of CloudWatch log groups for Fargate profiles"
  value = {
    infrastructure_default        = aws_cloudwatch_log_group.fargate_infrastructure_default.name
    infrastructure_kube_system    = aws_cloudwatch_log_group.fargate_infrastructure_kube_system.name
    infrastructure_external_secrets = aws_cloudwatch_log_group.fargate_infrastructure_external_secrets.name
    application                   = aws_cloudwatch_log_group.fargate_application.name
    monitoring_aws_otel_eks       = aws_cloudwatch_log_group.fargate_monitoring_aws_otel_eks.name
    monitoring_aws_observability  = aws_cloudwatch_log_group.fargate_monitoring_aws_observability.name
  }
}

#--------------------------------------------------
# IAM Policy Outputs
#--------------------------------------------------
output "fargate_logging_policy_arn" {
  description = "ARN of the IAM policy for Fargate logging"
  value       = aws_iam_policy.fargate_logging.arn
}
