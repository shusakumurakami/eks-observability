variable "resource_name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for EKS"
  type        = string
}

variable "adot_collector_namespace" {
  description = "Kubernetes namespace for ADOT Collector"
  type        = string
  default     = "aws-otel-eks"
}

variable "adot_collector_service_account" {
  description = "Kubernetes service account name for ADOT Collector (Prometheus)"
  type        = string
  default     = "adot-collector-prometheus"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}
