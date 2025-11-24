#--------------------------------------------------
# Observability Prometheus Module
#
# This module manages Prometheus-based observability infrastructure:
# 1. Amazon Managed Prometheus (AMP) workspace
# 2. IRSA for adot-prometheus collector
# 3. IAM policies for AMP remote write
#
# The ADOT Prometheus collector scrapes application metrics
# and sends them to AMP for storage and querying.
#--------------------------------------------------

#--------------------------------------------------
# AMP Workspace
#--------------------------------------------------
resource "aws_prometheus_workspace" "main" {
  alias = "${var.resource_name_prefix}-prometheus"
}

#--------------------------------------------------
# IRSA for ADOT Collector (Prometheus)
#--------------------------------------------------
module "irsa_adot_collector" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.2.0"

  name            = "${var.resource_name_prefix}-prometheus-irsa"
  use_name_prefix = false

  policies = {
    amp_remote_write = aws_iam_policy.amp_remote_write.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.adot_collector_namespace}:${var.adot_collector_service_account}"]
    }
  }
}

#--------------------------------------------------
# IAM Policy for AMP Remote Write
#--------------------------------------------------
resource "aws_iam_policy" "amp_remote_write" {
  name        = "${var.resource_name_prefix}-amp-remote-write-policy"
  description = "IAM policy for ADOT Collector to write metrics to AMP"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.main.arn
      }
    ]
  })
}
