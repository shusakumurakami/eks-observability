#--------------------------------------------------
# IAM Role for Grafana to access CloudWatch and AMP
#--------------------------------------------------
data "aws_iam_policy_document" "grafana_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "grafana" {
  name               = "${var.resource_name_prefix}-grafana-service-role"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role.json
}

#--------------------------------------------------
# IAM Policy for CloudWatch Access
#--------------------------------------------------
data "aws_iam_policy_document" "grafana_cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetInsightRuleReport"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:GetLogGroupFields",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults",
      "logs:GetLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "tag:GetResources"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "grafana_cloudwatch" {
  name        = "${var.resource_name_prefix}-grafana-cloudwatch-policy"
  description = "IAM policy for Grafana to access CloudWatch"
  policy      = data.aws_iam_policy_document.grafana_cloudwatch.json
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.grafana_cloudwatch.arn
}

#--------------------------------------------------
# IAM Policy for AMP Access
#--------------------------------------------------
data "aws_iam_policy_document" "grafana_amp" {
  statement {
    effect = "Allow"
    actions = [
      "aps:ListWorkspaces",
      "aps:DescribeWorkspace",
      "aps:QueryMetrics",
      "aps:GetLabels",
      "aps:GetSeries",
      "aps:GetMetricMetadata"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "grafana_amp" {
  name        = "${var.resource_name_prefix}-grafana-amp-policy"
  description = "IAM policy for Grafana to access Amazon Managed Prometheus"
  policy      = data.aws_iam_policy_document.grafana_amp.json
}

resource "aws_iam_role_policy_attachment" "grafana_amp" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.grafana_amp.arn
}
