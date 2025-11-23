variable "resource_name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "amp_workspace_id" {
  description = "Amazon Managed Prometheus workspace ID (optional - Grafana can discover AMP via IAM permissions)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "authentication_providers" {
  description = "List of authentication providers for Grafana workspace (AWS_SSO, SAML)"
  type        = list(string)
  default     = ["AWS_SSO"]

  validation {
    condition     = alltrue([for provider in var.authentication_providers : contains(["AWS_SSO", "SAML"], provider)])
    error_message = "Authentication providers must be either AWS_SSO or SAML."
  }
}
