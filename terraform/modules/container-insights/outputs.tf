output "container_insights_role_arn" {
  description = "IAM role ARN for Container Insights"
  value       = module.irsa_container_insights.arn
}

output "container_insights_service_account" {
  description = "Service account name for Container Insights"
  value       = var.container_insights_service_account
}

output "adot_collector_namespace" {
  description = "Namespace for ADOT Collector"
  value       = var.adot_collector_namespace
}
