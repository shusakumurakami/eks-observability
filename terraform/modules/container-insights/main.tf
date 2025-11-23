#--------------------------------------------------
# Observability Container Insights Module
#
# This module manages Container Insights infrastructure for EKS:
# - IRSA for adot-container-insights collector
# - IAM policies for CloudWatch Logs and Metrics
#
# Container Insights collector runs in var.adot_collector_namespace
# and sends metrics to CloudWatch.
#--------------------------------------------------

#--------------------------------------------------
# Data Sources
#--------------------------------------------------
data "aws_caller_identity" "current" {}

#--------------------------------------------------
# IRSA for Container Insights
#--------------------------------------------------
module "irsa_container_insights" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.2.0"

  name            = "${var.resource_name_prefix}-container-insights-irsa"
  use_name_prefix = false

  policies = {
    container_insights = aws_iam_policy.container_insights.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.adot_collector_namespace}:${var.container_insights_service_account}"]
    }
  }
}

#--------------------------------------------------
# IAM Policy for Container Insights
#--------------------------------------------------
resource "aws_iam_policy" "container_insights" {
  name        = "${var.resource_name_prefix}-container-insights-policy"
  description = "IAM policy for Container Insights to write to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/containerinsights/${var.eks_cluster_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "ContainerInsights"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
