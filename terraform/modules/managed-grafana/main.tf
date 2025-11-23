#--------------------------------------------------
# Data Sources
#--------------------------------------------------
data "aws_caller_identity" "current" {}

#--------------------------------------------------
# Wait for IAM propagation
#--------------------------------------------------
# IAM resources are eventually consistent and may not be immediately available
# across all AWS endpoints. Wait 20 seconds to ensure propagation.
resource "time_sleep" "wait_for_iam_propagation" {
  depends_on = [
    aws_iam_role.grafana,
    aws_iam_role_policy_attachment.grafana_cloudwatch,
    aws_iam_role_policy_attachment.grafana_amp
  ]

  create_duration = "20s"
}

#--------------------------------------------------
# AMG Workspace
#--------------------------------------------------
resource "aws_grafana_workspace" "main" {
  name                     = "${var.resource_name_prefix}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = var.authentication_providers
  permission_type          = "CUSTOMER_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn

  data_sources = [
    "CLOUDWATCH",
    "PROMETHEUS"
  ]

  notification_destinations = ["SNS"]

  depends_on = [time_sleep.wait_for_iam_propagation]
}
