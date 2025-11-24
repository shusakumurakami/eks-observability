# CI/CD Setup Guide

Setup instructions for the CI/CD environment in this repository.

## Overview

This repository is for **reference and learning purposes** and is not intended for deployment to production environments. The CI focuses on:

- **Code quality maintenance**: Terraform/Helm syntax validation and linting
- **Documentation consistency**: Preventing divergence between README and code
- **Security scanning**: Early detection of potential issues (warning level)

## CI Configuration

### Automated Checks

GitHub Actions automatically runs the following checks:

1. **Terraform Validation** (`.github/workflows/ci.yml`)
   - `terraform fmt -check`: Format checking
   - `terraform validate`: Syntax validation
   - `tflint`: Terraform linter

2. **Helm Validation**
   - `helm lint`: Chart syntax checking
   - `helm template`: Template rendering test

3. **Documentation Validation**
   - Broken link checking in Markdown files
   - Required section verification in CLAUDE.md

4. **Security Scanning**
   - `tfsec`: Terraform security scanner
   - `checkov`: IaC security checker
   - Both set to `soft_fail: true` (warnings only)

### Execution Timing

- On Pull Request creation/update
- On push to main branch

### Free Tier Optimization

To stay within GitHub Actions free tier, the following optimizations are implemented:

- `max-parallel: 2`: Limit parallel execution
- Caching: Terraform providers and TFLint plugins
- `concurrency`: Cancel duplicate runs

## Local Development Environment Setup

### 1. Pre-commit Hooks (Recommended)

Run automatic validation before commits:

```bash
# Install
pip install pre-commit

# Enable hooks
pre-commit install

# Manual execution (all files)
pre-commit run --all-files
```

Configuration file: `.pre-commit-config.yaml`

### 2. Required Tool Installation

#### macOS

```bash
# Via Homebrew
brew install terraform tflint helm

# Initialize TFLint plugins
tflint --init
```

#### Linux

```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip
unzip terraform_1.9.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 3. Local Validation Commands

#### Terraform

```bash
cd terraform/modules/<module-name>

# Format check
terraform fmt -check -recursive

# Initialize (no backend needed)
terraform init -backend=false

# Syntax validation
terraform validate

# Run linter
tflint --init
tflint
```

#### Helm

```bash
cd helm/<chart-name>

# Syntax check
helm lint .

# Template rendering
helm template test-release . \
  -f values/values-dev.yaml \
  --debug
```

#### Documentation

```bash
# Markdown link check (requires npm)
npm install -g markdown-link-check
markdown-link-check README.md -c .markdown-link-check.json
```

## Renovate (Automated Dependency Updates)

### Enabling Renovate

1. Install [Renovate App](https://github.com/apps/renovate) from GitHub Marketplace
2. Select the repository
3. `renovate.json` will be automatically detected

### Behavior

- **Execution timing**: Every weekend
- **Update targets**:
  - Terraform providers/modules
  - Helm charts
  - Docker images (ADOT collector, etc.)
  - GitHub Actions versions
- **PR creation**: Maximum 3 concurrent PRs
- **Auto-merge**: Disabled (manual review required)

## Troubleshooting

### CI Failures

#### Terraform Format Check Failed

```bash
# Auto-fix locally
terraform fmt -recursive terraform/
git add .
git commit -m "fix: terraform formatting"
```

#### Helm Lint Failed

```bash
# Check error details
helm lint ./helm/<chart-name> --debug

# Verify values.yaml syntax
yamllint ./helm/<chart-name>/values.yaml
```

#### Documentation Broken Links

```bash
# Check locally
markdown-link-check README.md

# Add links to ignore in .markdown-link-check.json
```

### Pre-commit Hook Errors

```bash
# Clear cache
pre-commit clean

# Reinstall
pre-commit install --install-hooks

# Skip specific hook
SKIP=terraform_validate git commit -m "message"
```

## Customizing CI Configuration

### Disable a Job

Comment out the relevant job in `.github/workflows/ci.yml`:

```yaml
# security:
#   name: Security Scan
#   runs-on: ubuntu-latest
#   steps:
#     ...
```

### Adjust TFLint Rules

Edit `.tflint.hcl`:

```hcl
# Disable specific rule
rule "aws_resource_missing_tags" {
  enabled = false
}
```

### Change Renovate Update Frequency

Edit `renovate.json`:

```json
{
  "schedule": [
    "every 2 weeks"  // Change from weekly to bi-weekly
  ]
}
```

## Reference Links

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [TFLint Rules](https://github.com/terraform-linters/tflint-ruleset-aws)
- [Renovate Documentation](https://docs.renovatebot.com/)
