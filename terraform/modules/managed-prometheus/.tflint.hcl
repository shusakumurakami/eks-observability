# TFLint configuration for Managed Prometheus module
# Inherits from root configuration but overrides specific rules

plugin "terraform" {
  enabled = true
  preset = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Disable tag checking - tags should be provided via default_tags in provider config
rule "aws_resource_missing_tags" {
  enabled = false
}
