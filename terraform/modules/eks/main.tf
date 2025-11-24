#--------------------------------------------------
# Data Sources
#--------------------------------------------------
data "aws_caller_identity" "current" {}

#--------------------------------------------------
# EKS Cluster
#--------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.8"

  name               = var.eks_cluster_name
  kubernetes_version = var.kubernetes_version

  # VPC configuration
  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.private_subnets

  # Cluster endpoint configuration
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  # Enable IRSA
  enable_irsa = true

  # Enable Deletion Protection
  deletion_protection = true

  # Use custom security groups
  create_security_group      = false
  security_group_id          = var.eks_cluster_security_group_id
  create_node_security_group = false

  # Additional security groups for pods
  additional_security_group_ids = var.eks_pods_security_group_ids

  # Cluster addons
  addons = {
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
      })
    }
    kube-proxy = {}
    vpc-cni    = {}
  }

  # Fargate Profiles
  fargate_profiles = {
    infrastructure = {
      name = "infrastructure"
      selectors = [
        {
          namespace = "default"
        },
        {
          namespace = "kube-system"
        },
        {
          namespace = "external-secrets"
        }
      ]

      subnet_ids = var.private_subnets

      iam_role_additional_policies = {
        FargateLogging = aws_iam_policy.fargate_logging.arn
      }
    }

    application = {
      name = "-application"
      selectors = [
        {
          namespace = var.application_name
        }
      ]

      subnet_ids = var.private_subnets

      iam_role_additional_policies = {
        FargateLogging = aws_iam_policy.fargate_logging.arn
      }
    }

    monitoring = {
      name = "monitoring"
      selectors = [
        {
          namespace = "aws-otel-eks"
        },
        {
          namespace = "aws-observability"
        }
      ]

      subnet_ids = var.private_subnets

      iam_role_additional_policies = {
        FargateLogging = aws_iam_policy.fargate_logging.arn
      }
    }
  }

  # CloudWatch logging
  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

#--------------------------------------------------
# Custom IAM Policy for Fargate Logging (Least Privilege)
#--------------------------------------------------
resource "aws_iam_policy" "fargate_logging" {
  name        = "${var.resource_name_prefix}-fargate-logging-policy"
  description = "Minimal permissions for Fargate logging to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.eks_cluster_name}/*"
      }
    ]
  })
}

#--------------------------------------------------
# CloudWatch Log Groups for Fargate (Namespace-based separation)
#--------------------------------------------------

# Infrastructure log groups
resource "aws_cloudwatch_log_group" "fargate_infrastructure_default" {
  name              = "/aws/eks/${var.eks_cluster_name}/infrastructure/default"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "fargate_infrastructure_kube_system" {
  name              = "/aws/eks/${var.eks_cluster_name}/infrastructure/kube-system"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "fargate_infrastructure_external_secrets" {
  name              = "/aws/eks/${var.eks_cluster_name}/infrastructure/external-secrets"
  retention_in_days = 7
}

# Application log groups
resource "aws_cloudwatch_log_group" "fargate_application" {
  name              = "/aws/eks/${var.eks_cluster_name}/application/${var.application_name}"
  retention_in_days = 30
}

# Monitoring log groups
resource "aws_cloudwatch_log_group" "fargate_monitoring_aws_otel_eks" {
  name              = "/aws/eks/${var.eks_cluster_name}/monitoring/aws-otel-eks"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "fargate_monitoring_aws_observability" {
  name              = "/aws/eks/${var.eks_cluster_name}/monitoring/aws-observability"
  retention_in_days = 7
}
