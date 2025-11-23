output "workspace_id" {
  description = "AMG workspace ID"
  value       = aws_grafana_workspace.main.id
}

output "workspace_endpoint" {
  description = "AMG workspace endpoint URL"
  value       = aws_grafana_workspace.main.endpoint
}

output "workspace_arn" {
  description = "AMG workspace ARN"
  value       = aws_grafana_workspace.main.arn
}

output "iam_role_arn" {
  description = "IAM role ARN for Grafana workspace"
  value       = aws_iam_role.grafana.arn
}
