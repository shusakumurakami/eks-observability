#--------------------------------------------------
# Required Variables
#--------------------------------------------------
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for EKS cluster and Fargate profiles"
  type        = list(string)
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  type        = string
}

variable "application_name" {
  description = "Name of the application for Fargate profile namespace"
  type        = string
}

#--------------------------------------------------
# Optional Variables
#--------------------------------------------------
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.31"
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster endpoint publicly"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_pods_security_group_ids" {
  description = "Additional security group IDs for EKS pods"
  type        = list(string)
  default     = []
}
