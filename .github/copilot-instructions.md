# GitHub Copilot Instructions for Self-Hosted DevOps Infrastructure

## Project Overview

This is a production-ready Terraform Infrastructure as Code (IaC) project for deploying autoscaling, ephemeral, cost-optimized CI/CD runners on Azure and AWS. The project supports GitLab Runner, GitHub Actions Runner, and Azure DevOps Agent.

## Core Principles

### 1. Security First
- **Default to secure configurations**: SSH disabled, IMDSv2 enabled, no public IPs, encrypted disks
- **Never weaken security defaults** without explicit documentation of risks in SECURITY.md
- **Mark all secrets as sensitive**: Always use `sensitive = true` for tokens, passwords, keys
- **Follow least privilege**: IAM/RBAC permissions should be minimal and specific
- **Validate security implications**: Before any change, consider attack vectors and compliance impact

### 2. Cost Optimization
- **Default to cost-effective options**: Spot instances, scale-to-zero, StandardSSD disks, 64GB default
- **Document cost tradeoffs**: When adding configuration options, include cost implications
- **Calculate monthly costs**: Provide estimated costs for different configurations
- **Optimize resource sizing**: Auto-detect runner counts, right-size VM/instance types

### 3. Multi-Cloud Consistency
- **Maintain feature parity**: Azure and AWS implementations should have equivalent capabilities
- **Use consistent naming**: Variables, resources, and patterns should align across clouds
- **Share common patterns**: Extract reusable logic to modules when possible
- **Document cloud-specific differences**: Clearly note when behavior differs between providers

### 4. Production Readiness
- **Comprehensive testing**: All changes must include validation strategy (see TESTING_GUIDE.md)
- **Graceful degradation**: Handle failures, spot terminations, and edge cases
- **Observability built-in**: Enable monitoring, logging, and health checks by default
- **Documentation completeness**: Update all relevant docs (README, QUICKSTART, SECURITY, TESTING_GUIDE)

## Terraform Best Practices

### Code Style and Formatting

```hcl
# REQUIRED: Always format code before committing
terraform fmt -recursive

# REQUIRED: Validate all configurations
terraform validate

# RECOMMENDED: Use consistent indentation (2 spaces)
resource "azurerm_virtual_machine_scale_set" "runner" {
  name                = var.vmss_name
  location            = var.location
  resource_group_name = var.resource_group_name
  # ... continue
}
```

### Variable Declarations

```hcl
# REQUIRED: Include description, type, and default (when appropriate)
variable "vm_sku" {
  description = "Azure VM size (e.g., Standard_D2s_v3). Default: Standard_D2s_v3 (2 vCPU, 8GB RAM, ~$21/mo spot). See QUICKSTART.md for sizing guide."
  type        = string
  default     = "Standard_D2s_v3"
}

# REQUIRED: Mark sensitive variables
variable "gitlab_token" {
  description = "GitLab runner registration token (starts with glrt-)"
  type        = string
  sensitive   = true
}

# REQUIRED: Use validation blocks for constraints
variable "min_instances" {
  description = "Minimum number of instances (0 = scale to zero for cost savings)"
  type        = number
  default     = 0

  validation {
    condition     = var.min_instances >= 0
    error_message = "min_instances must be >= 0"
  }
}

# RECOMMENDED: Group related variables in comments
# =============================================================================
# CI/CD Platform Configuration
# =============================================================================

variable "gitlab_url" {
  description = "GitLab instance URL (e.g., https://gitlab.com)"
  type        = string
}
```

### Resource Naming

```hcl
# REQUIRED: Use descriptive, consistent resource names
resource "azurerm_resource_group" "runner" {
  name     = "${var.project_name}-rg"
  location = var.location
  
  tags = local.common_tags
}

# REQUIRED: Use local variables for computed values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Self-Hosted-Runner"
  }
  
  vmss_name = "${var.project_name}-gitlab-runner"
}
```

### Module Structure

```hcl
# REQUIRED: Modules should have clear inputs and outputs
# modules/azure-vmss/variables.tf
variable "name" {
  description = "Name of the Virtual Machine Scale Set"
  type        = string
}

# modules/azure-vmss/outputs.tf
output "vmss_id" {
  description = "ID of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "vmss_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
}
```

### State Management

```hcl
# RECOMMENDED: Use remote state for production
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate"
    container_name       = "state"
    key                  = "runners/gitlab/terraform.tfstate"
  }
}

# REQUIRED: Pin provider versions
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

## Project-Specific Patterns

### Adding New Configuration Options

```hcl
# 1. Add variable with comprehensive documentation
variable "enable_accelerated_networking" {
  description = <<-EOT
    Enable Azure Accelerated Networking for improved network performance.
    
    **Performance Impact:**
    - ✓ Up to 30% lower latency
    - ✓ Higher throughput for network-intensive workloads
    - ✓ Better consistency under load
    
    **Cost Impact:**
    - No additional cost
    
    **Compatibility:**
    - Requires supported VM size (Dv3, Ev3, Fv2, etc.)
    - Not available on all VM sizes
    
    **Default:** false (for maximum compatibility)
  EOT
  type        = bool
  default     = false
}

# 2. Implement with proper conditional logic
resource "azurerm_linux_virtual_machine_scale_set" "runner" {
  # ... other configuration
  
  network_interface {
    name    = "nic"
    primary = true
    
    enable_accelerated_networking = var.enable_accelerated_networking
    
    # ... rest of config
  }
}

# 3. Document in terraform.tfvars.example
# terraform.tfvars.example
# enable_accelerated_networking = false  # Enable for network-intensive workloads

# 4. Update README.md with usage example and guidance
```

### Security-Sensitive Changes

```hcl
# REQUIRED: Document security implications when changing defaults

# BAD: Silent security weakening
variable "enable_ssh_access" {
  description = "Enable SSH access"
  type        = bool
  default     = true  # WRONG! This weakens security
}

# GOOD: Secure default with clear documentation
variable "enable_ssh_access" {
  description = <<-EOT
    Enable SSH access to runner instances.
    
    **⚠️ Security Impact:**
    When enabled:
    - Instances expose SSH port (22)
    - Must configure ssh_cidr_blocks to restrict access
    - Increases attack surface
    - Requires SSH key management
    
    **Recommended Alternatives:**
    - Azure: Use Azure Bastion for secure access
    - AWS: Use AWS Systems Manager Session Manager
    
    **Default:** false (secure by default)
    **See:** SECURITY.md for detailed security considerations
  EOT
  type        = bool
  default     = false
}

# REQUIRED: Add validation to prevent insecure configurations
variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access. Required if enable_ssh_access is true."
  type        = list(string)
  default     = []

  validation {
    condition = (
      length(var.ssh_cidr_blocks) == 0 ||
      !contains(var.ssh_cidr_blocks, "0.0.0.0/0")
    )
    error_message = "SSH access from 0.0.0.0/0 is not allowed for security reasons. Use specific CIDR blocks."
  }
}
```

### Cloud-Init / User Data Patterns

```bash
#!/bin/bash
# REQUIRED: Include comprehensive error handling and logging

set -euo pipefail

# REQUIRED: Log all output for debugging
exec 1> >(tee -a /var/log/runner-init.log)
exec 2>&1

echo "$(date): Starting runner initialization"

# REQUIRED: Use functions for reusable logic
wait_for_docker() {
    local max_attempts=30
    local attempt=0
    
    until docker ps &> /dev/null || [ $attempt -eq $max_attempts ]; do
        echo "Waiting for Docker... (attempt $((attempt + 1))/$max_attempts)"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        echo "ERROR: Docker failed to start after $max_attempts attempts"
        return 1
    fi
    
    echo "Docker is ready"
}

# REQUIRED: Handle failures gracefully
register_runner() {
    local max_retries=5
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if docker run --rm -v /runner-config:/etc/gitlab-runner \
            ${runner_image} register ... ; then
            echo "Runner registered successfully"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        echo "Registration attempt $retry_count failed, retrying..."
        sleep 10
    done
    
    echo "ERROR: Failed to register runner after $max_retries attempts"
    return 1
}

# REQUIRED: Clean up on exit
cleanup() {
    echo "$(date): Cleanup initiated"
    # Unregister runners, stop containers, etc.
}
trap cleanup EXIT

# Execute main logic
wait_for_docker || exit 1
register_runner || exit 1

echo "$(date): Runner initialization complete"
```

### Autoscaling Configuration

```hcl
# REQUIRED: Configure autoscaling with clear documentation

# Azure VMSS Autoscale
resource "azurerm_monitor_autoscale_setting" "vmss" {
  name                = "${var.vmss_name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "AutoScale"

    capacity {
      default = var.default_instances  # Normal load
      minimum = var.min_instances      # Scale to zero for cost savings
      maximum = var.max_instances      # Cap to prevent runaway costs
    }

    # REQUIRED: Conservative scale-out (prefer running jobs)
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"    # 1 minute granularity
        statistic          = "Average"
        time_window        = "PT5M"    # 5 minute window
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70        # Scale out at 70% CPU
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"               # Add one instance at a time
        cooldown  = "PT3M"            # 3 minute cooldown
      }
    }

    # REQUIRED: Aggressive scale-in (reduce costs quickly)
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"   # 10 minute window (longer)
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30        # Scale in at 30% CPU
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"            # 5 minute cooldown
      }
    }
  }
}
```

## Testing Requirements

### Pre-Commit Validation

```bash
# REQUIRED: Run these checks before every commit

# Format all Terraform files
terraform fmt -recursive

# Validate all configurations
for dir in modules/*/ azure/*/ aws/*/; do
    if [ -f "$dir/main.tf" ]; then
        echo "Validating $dir"
        (cd "$dir" && terraform init -backend=false && terraform validate)
    fi
done

# Check for common issues
terraform fmt -check -recursive
```

### Testing New Features

```bash
# REQUIRED: Test in a dedicated test environment

# 1. Deploy to test environment
cd azure/gitlab-runner  # or aws/gitlab-runner
cp terraform.tfvars.example terraform.tfvars
# Edit with test values

terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 2. Verify functionality
# - Check runner registration
# - Run test CI/CD jobs
# - Verify autoscaling behavior
# - Test spot termination handling
# - Validate security configuration

# 3. Clean up
terraform destroy -auto-approve
```

## Documentation Standards

### README Updates

```markdown
## New Feature Name

Brief description of the feature and its purpose.

### Configuration

\`\`\`hcl
# Example configuration
variable_name = "value"
\`\`\`

### Cost Impact

- **Default configuration:** $X/month
- **With feature enabled:** $Y/month
- **Difference:** +$Z/month (+N%)

### Security Considerations

- ✓ Benefit 1
- ⚠️ Warning 1
- ✗ Risk 1 (and how to mitigate)

### Performance Impact

- Expected improvement/change in [metric]
- Tradeoffs to consider

### Examples

See [terraform.tfvars.example](terraform.tfvars.example) for usage examples.
```

### Commit Message Format

```
type(scope): brief description

Detailed explanation of changes, why they were needed,
and any important context.

Impact:
- Cost: +/- $X/month
- Security: [Enhanced|Neutral|See notes]
- Performance: [Improved|Neutral|Degraded]

Breaking Changes:
- List any breaking changes
- Include migration instructions

Testing:
- How changes were tested
- Test results summary
```

## Common Patterns

### Conditional Resources

```hcl
# GOOD: Use count for optional resources
resource "azurerm_public_ip" "runner" {
  count               = var.create_public_ip ? 1 : 0
  name                = "${var.project_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# GOOD: Reference conditional resources safely
network_interface {
  name    = "nic"
  primary = true
  
  ip_configuration {
    name      = "internal"
    subnet_id = var.subnet_id
    
    public_ip_address_id = var.create_public_ip ? azurerm_public_ip.runner[0].id : null
  }
}
```

### Dynamic Blocks

```hcl
# GOOD: Use dynamic blocks for repeated configuration
resource "aws_security_group" "runner" {
  name        = "${var.project_name}-runner-sg"
  description = "Security group for self-hosted runners"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    
    content {
      description = "SSH from allowed CIDR blocks"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
    }
  }

  # Multiple rules from list
  dynamic "egress" {
    for_each = var.egress_rules
    
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}
```

### Data Sources

```hcl
# GOOD: Use data sources for external references
data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

# GOOD: Query for latest images
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

## Anti-Patterns to Avoid

### ❌ Hardcoded Values

```hcl
# BAD: Hardcoded values
resource "azurerm_resource_group" "runner" {
  name     = "my-runner-rg"  # Should be parameterized
  location = "East US"        # Should be variable
}

# GOOD: Parameterized
resource "azurerm_resource_group" "runner" {
  name     = "${var.project_name}-rg"
  location = var.location
}
```

### ❌ Insecure Defaults

```hcl
# BAD: Insecure default
variable "ssh_allowed_cidrs" {
  default = ["0.0.0.0/0"]  # NEVER do this
}

# GOOD: Secure default with validation
variable "ssh_cidr_blocks" {
  default = []  # Empty = no SSH access
  
  validation {
    condition     = !contains(var.ssh_cidr_blocks, "0.0.0.0/0")
    error_message = "SSH from 0.0.0.0/0 is not allowed"
  }
}
```

### ❌ Missing Documentation

```hcl
# BAD: No context
variable "threshold" {
  type    = number
  default = 70
}

# GOOD: Clear documentation
variable "cpu_scale_out_threshold" {
  description = <<-EOT
    CPU utilization percentage that triggers scaling out (adding instances).
    Lower values = more aggressive scaling = higher costs.
    Higher values = more conservative scaling = potential job queuing.
    
    Recommended ranges:
    - Development: 80-90% (cost-optimized)
    - Production: 60-75% (performance-optimized)
    
    Default: 70% (balanced)
  EOT
  type    = number
  default = 70

  validation {
    condition     = var.cpu_scale_out_threshold > 0 && var.cpu_scale_out_threshold < 100
    error_message = "cpu_scale_out_threshold must be between 1 and 99"
  }
}
```

### ❌ Unclear Variable Names

```hcl
# BAD: Ambiguous names
variable "size" { }      # What size?
variable "enabled" { }   # What's enabled?
variable "timeout" { }   # Timeout for what?

# GOOD: Descriptive names
variable "vm_sku" { }
variable "enable_ssh_access" { }
variable "runner_registration_timeout_seconds" { }
```

## Git Workflow

### Branch Strategy

**REQUIRED**: Always create changes in a separate branch, never commit directly to main/master.

```bash
# Create feature branch with descriptive name
git checkout -b feature/add-spot-diversification
git checkout -b fix/security-group-rules
git checkout -b docs/update-cost-guidance

# Make changes, commit with proper messages
git add .
git commit -m "feat(aws): add spot instance diversification

Implements mixed instances policy for AWS ASG to improve
spot instance availability across multiple instance types.

Impact:
- Cost: Neutral (still using spot instances)
- Security: Neutral
- Performance: Improved (better spot availability)

Testing:
- Validated terraform fmt and validate
- Tested deployment in dev environment
- Verified spot instance mix in AWS console"

# Push branch
git push -u origin feature/add-spot-diversification
```

### Pull Request Creation

**OPTIONAL**: Create GitHub Pull Requests when:
- ✅ Changes are significant or affect multiple files
- ✅ Changes modify security configurations
- ✅ Changes impact cost or performance characteristics
- ✅ Working in a team environment requiring code review
- ✅ Changes need documentation review before merge

**Skip PR for**:
- Minor documentation fixes (typos, formatting)
- Local testing branches not intended for merge
- Emergency hotfixes (but document thoroughly in commit)

```bash
# After pushing branch, create PR using GitHub CLI (if available)
gh pr create \
  --title "Add spot instance diversification for AWS ASG" \
  --body "## Summary
Implements mixed instances policy to improve spot availability.

## Changes
- Added spot_instance_types variable
- Updated launch template configuration
- Added validation for instance type list

## Testing
- [x] terraform fmt
- [x] terraform validate
- [x] Deployed to test environment
- [x] Verified autoscaling behavior
- [x] Checked cost impact

## Documentation
- [x] Updated README.md
- [x] Updated terraform.tfvars.example
- [x] Added cost impact notes

## Checklist
- [x] Security defaults maintained
- [x] Multi-cloud consistency preserved
- [x] Cost optimization principles followed
- [x] All documentation updated" \
  --label "enhancement" \
  --label "terraform"
```

### PR Best Practices

When creating pull requests:

1. **Use descriptive titles**: Follow conventional commit format
   - `feat(azure): add accelerated networking support`
   - `fix(aws): correct security group egress rules`
   - `docs: update cost estimation guide`

2. **Include comprehensive description**:
   - Summary of changes
   - Why changes were needed
   - Impact assessment (cost, security, performance)
   - Testing performed
   - Documentation updates

3. **Add appropriate labels**:
   - `terraform` - Infrastructure changes
   - `security` - Security-related changes
   - `cost-optimization` - Cost impact changes
   - `documentation` - Documentation only
   - `breaking-change` - Breaking changes

4. **Request reviews** when:
   - Changes affect security configurations
   - Modifications to shared modules
   - Breaking changes or API modifications
   - Complex autoscaling logic changes

## AI Assistant Guidance

When working on this project:

1. **Always read relevant documentation first**: Check QUICKSTART.md, SECURITY.md, and TESTING_GUIDE.md
2. **Create a feature branch**: Never commit directly to main/master
3. **Maintain security posture**: Never weaken security defaults without explicit user request and documentation
4. **Consider costs**: Every change should be evaluated for cost impact
5. **Test thoroughly**: Use patterns from TESTING_GUIDE.md for validation
6. **Update documentation**: Changes must be reflected in all relevant docs
7. **Follow multi-cloud patterns**: Keep Azure and AWS implementations consistent
8. **Validate thoroughly**: Run `terraform fmt` and `terraform validate` on all changes
9. **Think production-ready**: Every change should be production-grade, not a proof-of-concept
10. **Consider PR creation**: For significant changes, suggest creating a pull request for review

## Questions to Ask Before Coding

Before implementing changes, consider:

- ✅ Does this maintain or improve security?
- ✅ What is the cost impact?
- ✅ Does this work on both Azure and AWS (if applicable)?
- ✅ How will this be tested?
- ✅ What documentation needs updating?
- ✅ Are there any breaking changes?
- ✅ Is this production-ready?
- ✅ Does this follow Terraform best practices?

## Getting Help

- **Terraform Best Practices**: [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- **Azure Provider**: [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- **AWS Provider**: [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- **Project Documentation**: See README.md, QUICKSTART.md, SECURITY.md, TESTING_GUIDE.md

---

**Remember**: This is production infrastructure. Every change impacts real costs, security posture, and system reliability. Code thoughtfully, test thoroughly, document completely.
