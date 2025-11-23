output "workspace_id" {
  description = "AMP workspace ID"
  value       = aws_prometheus_workspace.main.id
}

output "workspace_arn" {
  description = "AMP workspace ARN"
  value       = aws_prometheus_workspace.main.arn
}

output "workspace_endpoint" {
  description = "AMP workspace endpoint for remote write"
  value       = aws_prometheus_workspace.main.prometheus_endpoint
}

output "adot_collector_role_arn" {
  description = "IAM role ARN for ADOT Collector (Prometheus)"
  value       = module.irsa_adot_collector.iam_role_arn
}

output "adot_collector_service_account" {
  description = "Service account name for ADOT Collector (Prometheus)"
  value       = var.adot_collector_service_account
}

output "adot_collector_namespace" {
  description = "Namespace for ADOT Collector"
  value       = var.adot_collector_namespace
}
