# TFLint configuration for EKS observability reference repository
# https://github.com/terraform-linters/tflint

config {
  # Enable warnings that are disabled by default
  force = false
  # Do not ignore disabled rules
  disabled_by_default = false
}

# AWS plugin configuration
plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  # Disable deep checking (does not query actual AWS resources)
  deep_check = false
}

# Terraform plugin configuration
plugin "terraform" {
  enabled = true
  version = "0.8.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"

  preset = "recommended"
}

# Rules configuration
# Note: Tags are expected to be defined via default_tags in the provider configuration
# when using these modules, so we disable the tag checking at the module level
rule "aws_resource_missing_tags" {
  enabled = false
}

rule "terraform_naming_convention" {
  enabled = true

  variable {
    format = "snake_case"
  }

  locals {
    format = "snake_case"
  }

  output {
    format = "snake_case"
  }

  resource {
    format = "snake_case"
  }

  module {
    format = "snake_case"
  }
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}
