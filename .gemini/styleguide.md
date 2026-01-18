# Terraform & Infrastructure Style Guide for Agentic Development

This guide defines coding standards and best practices for AI-assisted development of this Terraform infrastructure project. Following these patterns ensures consistency, maintainability, and enables effective collaboration between human developers and AI agents.

## Core Principles

### 1. Security First
- **Default to secure configurations**: SSH disabled, IMDSv2 enabled, no public IPs, encrypted disks
- **Never weaken security defaults** without explicit documentation in SECURITY.md
- **Mark all secrets as sensitive**: Always use `sensitive = true` for tokens, passwords, keys
- **Follow least privilege**: IAM/RBAC permissions should be minimal and specific
- **Document security tradeoffs**: When adding options that impact security, include comprehensive warnings

### 2. Cost Optimization
- **Default to cost-effective options**: Spot instances, scale-to-zero, right-sized resources
- **Document cost implications**: Include monthly cost estimates in variable descriptions
- **Calculate tradeoffs**: Explain cost vs. performance vs. reliability tradeoffs
- **Optimize resource sizing**: Auto-detect when possible, provide sizing guidance

### 3. Multi-Cloud Consistency
- **Maintain feature parity**: AWS and Azure implementations should have equivalent capabilities
- **Use consistent naming**: Variables, resources, and patterns should align across clouds
- **Share common patterns**: Extract reusable logic to modules when possible
- **Document cloud-specific differences**: Clearly note when behavior differs

### 4. Production Readiness
- **Comprehensive testing**: All changes must include validation strategy
- **Graceful degradation**: Handle failures, spot terminations, edge cases
- **Observability built-in**: Enable monitoring, logging, health checks by default
- **Documentation completeness**: Update all relevant docs when making changes

## Terraform (HCL) Standards

### Formatting
```bash
# REQUIRED: Format before every commit
terraform fmt -recursive

# REQUIRED: Validate all configurations
terraform validate
```

### Naming Conventions
```hcl
# GOOD: Descriptive snake_case names
resource "azurerm_linux_virtual_machine_scale_set" "runner" {
  name = "${var.project_name}-vmss"
}

# BAD: Unclear abbreviations
resource "azurerm_linux_virtual_machine_scale_set" "r" {
  name = "vmss"
}
```

### Variable Declarations

#### Required Elements
Every variable MUST include:
1. **description**: Comprehensive documentation (use heredoc for complex variables)
2. **type**: Explicit type constraint
3. **default**: Default value when applicable
4. **validation**: Constraints and validation rules

#### Comprehensive Variable Pattern
```hcl
variable "vm_sku" {
  description = <<-EOT
    Azure VM size/SKU.
    
    Cost/Performance Tradeoffs:
    - Standard_B2s: Lowest cost (~$30/mo), burstable CPU, good for light workloads
    - Standard_D2s_v3: Balanced cost/performance (~$70/mo), consistent CPU (RECOMMENDED)
    - Standard_D4s_v3: Higher performance (~$140/mo), 4 vCPUs, for compute-intensive jobs
    
    Security Impact: None
    Default: Standard_D2s_v3 (balanced cost and consistent performance)
  EOT
  type        = string
  default     = "Standard_D2s_v3"

  validation {
    condition     = can(regex("^Standard_", var.vm_sku))
    error_message = "VM SKU must start with 'Standard_'"
  }
}

# REQUIRED: Mark sensitive variables
variable "github_token" {
  description = "GitHub runner registration token"
  type        = string
  sensitive   = true  # CRITICAL: Prevents token exposure in logs
}
```

#### Variable Description Best Practices
```hcl
variable "enable_feature" {
  description = <<-EOT
    [Brief one-line summary]
    
    [Detailed explanation of what this does]
    
    **Impact:**
    - Cost: [cost implications]
    - Security: [security implications]
    - Performance: [performance implications]
    
    **Options:**
    - true: [what happens when enabled]
    - false: [what happens when disabled]
    
    **Recommendations:**
    [guidance on when to use which value]
    
    Default: [default value] ([reason])
  EOT
  type        = bool
  default     = true
}
```

### Security-Sensitive Variables

#### Pattern for Variables That May Trigger Security Alerts
```hcl
# trivy:ignore:AVD-AWS-0104 "Justification for security scanner"
# tfsec:ignore:aws-ec2-no-public-egress-sgr "Required for CI/CD operations"
variable "egress_cidr_blocks" {
  description = <<-EOT
    CIDR blocks for outbound traffic - USE WITH UNDERSTANDING.
    
    ⚠️ Security Impact:
    [Detailed explanation of security implications]
    
    ✓ RECOMMENDED: [recommended configuration]
    ⚠️ WARNING: [what to be careful about]
    
    Default: [value] ([justification])
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
```

### Resource Definitions

#### Resource Naming
```hcl
# GOOD: Descriptive, consistent naming
resource "azurerm_resource_group" "runner" {
  name     = "${var.project_name}-rg"
  location = var.location
  
  tags = local.common_tags
}

# GOOD: Use local variables for computed/shared values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Self-Hosted-Runner"
  }
}
```

#### Conditional Resources
```hcl
# GOOD: Use count for optional resources
resource "azurerm_public_ip" "runner" {
  count               = var.create_public_ip ? 1 : 0
  name                = "${var.project_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# GOOD: Safe reference to conditional resources
network_interface {
  ip_configuration {
    public_ip_address_id = var.create_public_ip ? azurerm_public_ip.runner[0].id : null
  }
}
```

#### Dynamic Blocks
```hcl
# GOOD: Dynamic blocks for repeated configuration
resource "aws_security_group" "runner" {
  name   = "${var.project_name}-sg"
  vpc_id = var.vpc_id

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
}
```

### Validation Patterns

#### Input Validation
```hcl
variable "min_instances" {
  description = "Minimum number of instances (0 = scale to zero)"
  type        = number
  default     = 0

  validation {
    condition     = var.min_instances >= 0
    error_message = "min_instances must be >= 0"
  }
}

# Cross-variable validation
variable "ssh_cidr_blocks" {
  description = "CIDR blocks for SSH access"
  type        = list(string)
  default     = []

  validation {
    condition = (
      var.enable_ssh_access == false || 
      length(var.ssh_cidr_blocks) > 0
    )
    error_message = "ssh_cidr_blocks required when enable_ssh_access is true"
  }
  
  validation {
    condition = (
      length(var.ssh_cidr_blocks) == 0 ||
      !contains(var.ssh_cidr_blocks, "0.0.0.0/0")
    )
    error_message = "SSH from 0.0.0.0/0 not allowed for security"
  }
}
```

### Module Structure

#### Module Organization
```
modules/
  azure-vmss/
    main.tf          # Primary resource definitions
    variables.tf     # Input variables with descriptions
    outputs.tf       # Exposed values for consumers
    tests/
      basic.tftest.hcl  # Terraform native tests
```

#### Module Outputs
```hcl
# GOOD: Descriptive outputs with documentation
output "vmss_id" {
  description = "ID of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "vmss_principal_id" {
  description = "Principal ID of system-assigned managed identity"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
}
```

### Comments and Documentation

#### Inline Comments
```hcl
# Section headers for logical grouping
# =============================================================================
# Network Configuration
# =============================================================================

# Explanatory comments for complex logic
# Scale out aggressively to handle job queues
# Scale in conservatively to avoid interrupting jobs
rule {
  metric_trigger {
    threshold = 70  # Scale out at 70% CPU
  }
}

# IMPORTANT: Document why certain patterns are used
# Using count instead of for_each because order matters for priority
resource "azurerm_network_security_rule" "rules" {
  count = length(var.security_rules)
  # ...
}
```

#### Documentation Comments for AI Context
```hcl
# AI-CONTEXT: This variable controls the default egress behavior
# Changed from unrestricted (0.0.0.0/0, all ports) to HTTPS-only (443/tcp)
# for security hardening. Users can override in terraform.tfvars.
# Related: SECURITY.md, aws/*/variables.tf
variable "egress_protocol" {
  description = "Protocol for outbound traffic"
  type        = string
  default     = "tcp"
}
```

## Cloud-Init / User Data Scripts

### Script Structure
```bash
#!/bin/bash
# REQUIRED: Strict error handling
set -euo pipefail

# REQUIRED: Comprehensive logging
exec 1> >(tee -a /var/log/runner-init.log)
exec 2>&1

echo "$(date): Starting runner initialization"

# REQUIRED: Reusable functions with error handling
wait_for_service() {
    local service_name="$1"
    local max_attempts=30
    local attempt=0
    
    until systemctl is-active --quiet "$service_name" || [ $attempt -eq $max_attempts ]; do
        echo "Waiting for $service_name... (attempt $((attempt + 1))/$max_attempts)"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        echo "ERROR: $service_name failed to start"
        return 1
    fi
    
    echo "$service_name is ready"
}

# REQUIRED: Cleanup trap
cleanup() {
    echo "$(date): Cleanup initiated"
    # Cleanup operations
}
trap cleanup EXIT

# Execute with error handling
wait_for_service "docker" || exit 1

echo "$(date): Initialization complete"
```

## Documentation Standards

### README.md Structure
```markdown
# [Module/Component Name]

Brief description of what this module does.

## Features

- Feature 1
- Feature 2

## Prerequisites

- Requirement 1
- Requirement 2

## Usage

### Basic Example
\`\`\`hcl
module "example" {
  source = "./modules/example"
  
  variable1 = "value1"
}
\`\`\`

### Advanced Example
\`\`\`hcl
# More complex usage
\`\`\`

## Cost Estimate

- Default configuration: $X/month
- With feature Y: $Y/month

## Security Considerations

- ✓ Security benefit 1
- ⚠️ Warning 1
- ✗ Risk 1 (and mitigation)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| var1 | Description | string | "default" | no |

## Outputs

| Name | Description |
|------|-------------|
| out1 | Description |

## Testing

See [TESTING_GUIDE.md](../../TESTING_GUIDE.md)

## License

MIT - See [LICENSE](../../LICENSE)
```

### terraform.tfvars.example Structure
```hcl
# =============================================================================
# Required Variables
# =============================================================================

# [Platform] Configuration
platform_url = "https://example.com"  # Your platform URL
platform_token = "token-value"        # Get from platform settings

# =============================================================================
# Optional Variables (Uncomment to customize)
# =============================================================================

# Cost Optimization
# use_spot_instances = true  # Default: true (cost savings)
# min_instances = 0          # Default: 0 (scale to zero)

# Security (defaults are secure)
# enable_ssh_access = false  # Default: false (SSH disabled)

# Performance
# vm_sku = "Standard_D2s_v3"  # Default: balanced performance
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
    CPU utilization % that triggers scaling out.
    
    Recommended: 60-75% for production, 80-90% for dev
    Default: 70% (balanced)
  EOT
  type        = number
  default     = 70

  validation {
    condition     = var.cpu_scale_out_threshold > 0 && var.cpu_scale_out_threshold < 100
    error_message = "Must be between 1 and 99"
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

## Git Workflow for AI Agents

### Branch Naming
```bash
# Feature branches
feature/add-spot-diversification
feature/azure-private-endpoints

# Bug fixes
fix/security-group-rules
fix/spot-termination-handling

# Documentation
docs/update-cost-guidance
docs/add-testing-examples
```

### Commit Message Format
```
type(scope): brief description (max 72 chars)

Detailed explanation of changes, why they were needed,
and any important context. Wrap at 72 characters.

Impact:
- Cost: +/- $X/month
- Security: Enhanced/Neutral/See notes
- Performance: Improved/Neutral/Degraded

Breaking Changes:
- List any breaking changes
- Include migration instructions

Testing:
- terraform fmt ✓
- terraform validate ✓
- Deployed to test environment ✓
- Verified [specific functionality] ✓
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, no code change
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance tasks

## State Management

### Backend Configuration
```hcl
# DO NOT commit credentials in backend config
terraform {
  backend "azurerm" {
    # Use environment variables or backend config file
    # ARM_ACCESS_KEY, ARM_CLIENT_ID, etc.
  }
}

# Pin provider versions
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

### .gitignore Essentials
```
# Local state
*.tfstate
*.tfstate.*

# Sensitive files
*.tfvars
!terraform.tfvars.example
.terraform/
.terraform.lock.hcl

# Logs
*.log

# OS files
.DS_Store
```

## Testing Requirements

### Pre-Commit Validation
```bash
# REQUIRED before every commit
terraform fmt -recursive
terraform validate

# Recommended
terraform plan
```

### Module Testing
```hcl
# tests/basic.tftest.hcl
run "test_basic_deployment" {
  command = plan

  assert {
    condition     = azurerm_resource_group.test.location == "East US"
    error_message = "Resource group location incorrect"
  }
}
```

## Directory Structure

```
.
├── .github/
│   ├── copilot-instructions.md  # AI agent instructions
│   └── workflows/                # CI/CD pipelines
├── .gemini/
│   └── styleguide.md            # This file
├── aws/
│   ├── azure-devops-agent/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── network.tf
│   │   ├── user-data.sh
│   │   ├── terraform.tfvars.example
│   │   └── tests/
│   ├── github-runner/
│   └── gitlab-runner/
├── azure/
│   ├── azure-devops-agent/
│   ├── github-runner/
│   └── gitlab-runner/
├── modules/
│   ├── aws-asg/
│   └── azure-vmss/
├── docs/
│   └── TERRAFORM_TESTING.md
├── scripts/
├── ARCHITECTURE.md
├── LICENSE
├── QUICKSTART.md
├── README.md
├── SECURITY.md
└── TESTING_GUIDE.md
```

## AI Agent Checklist

Before proposing changes, verify:
- ✅ Does this maintain or improve security?
- ✅ What is the cost impact?
- ✅ Does this work on both AWS and Azure?
- ✅ How will this be tested?
- ✅ What documentation needs updating?
- ✅ Are there any breaking changes?
- ✅ Is this production-ready?
- ✅ Does this follow all patterns in this guide?
- ✅ Have I run `terraform fmt` and `terraform validate`?
- ✅ Have I updated terraform.tfvars.example?

## Questions to Ask

When uncertain about implementation:
1. What is the security impact?
2. What are the cost implications?
3. How does this affect existing deployments?
4. What happens in failure scenarios?
5. Is this the simplest solution that works?
6. Can this be tested automatically?
7. How will users know how to use this?
8. Does this align with cloud provider best practices?

## References

- **Project Documentation**: README.md, QUICKSTART.md, SECURITY.md, TESTING_GUIDE.md
- **Terraform Best Practices**: [terraform.io/docs/language/syntax/style.html](https://www.terraform.io/docs/language/syntax/style.html)
- **Azure Provider**: [registry.terraform.io/providers/hashicorp/azurerm/latest/docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- **AWS Provider**: [registry.terraform.io/providers/hashicorp/aws/latest/docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Remember**: This is production infrastructure. Every change impacts real costs, security posture, and system reliability. Code thoughtfully, test thoroughly, document completely.
