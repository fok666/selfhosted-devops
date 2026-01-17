# Terraform Testing Guide

## Overview

This project uses **Terraform's native testing framework** (available since Terraform 1.6) for validating infrastructure configurations without requiring expensive cloud resources or third-party mocking services like LocalStack. This approach is:

- ✅ **Free**: No cost for test execution
- ✅ **Fast**: Tests run in seconds using `terraform plan`
- ✅ **Cloud-agnostic**: Works for both AWS and Azure
- ✅ **Built-in**: No additional tools or services required
- ✅ **Comprehensive**: Validates configurations, security, cost optimization, and compliance

## Test Structure

Tests are organized in `tests/` directories within each module and configuration:

```
project/
├── modules/
│   ├── aws-asg/
│   │   ├── main.tf
│   │   └── tests/
│   │       └── basic.tftest.hcl          # Module unit tests
│   └── azure-vmss/
│       ├── main.tf
│       └── tests/
│           └── basic.tftest.hcl          # Module unit tests
├── aws/
│   └── gitlab-runner/
│       ├── main.tf
│       └── tests/
│           └── integration.tftest.hcl     # Integration tests
└── azure/
    └── gitlab-runner/
        ├── main.tf
        └── tests/
            └── integration.tftest.hcl     # Integration tests
```

## Test Types

### 1. Unit Tests (Module Tests)

**Purpose**: Validate individual modules in isolation

**Location**: `modules/*/tests/`

**What they test**:
- Variable validation and constraints
- Resource configuration correctness
- Security defaults (IMDSv2, SSH disabled, encryption)
- Spot instance configuration
- Autoscaling settings
- Disk configuration

**Example**: [modules/aws-asg/tests/basic.tftest.hcl](../modules/aws-asg/tests/basic.tftest.hcl)

```hcl
run "validate_spot_configuration" {
  command = plan

  variables {
    project_name  = "test-runner"
    use_spot_instances = true
    spot_max_price = "0.05"
    # ... other required variables
  }

  assert {
    condition     = aws_launch_template.runner.instance_market_options[0].market_type == "spot"
    error_message = "Launch template should use spot instances"
  }
}
```

### 2. Integration Tests

**Purpose**: Validate complete configurations with networking and dependencies

**Location**: `aws/*/tests/`, `azure/*/tests/`

**What they test**:
- Complete runner setup
- Network configuration (VPC/VNet, subnets, security groups)
- Security hardening
- Cost optimization patterns
- High availability configurations

**Example**: [aws/gitlab-runner/tests/integration.tftest.hcl](../aws/gitlab-runner/tests/integration.tftest.hcl)

```hcl
run "validate_security_hardening" {
  command = plan

  variables {
    environment = "production"
    enable_ssh_access = false
    enable_imdsv2 = true
    encrypted_disk = true
    # ... other variables
  }

  assert {
    condition     = var.enable_ssh_access == false
    error_message = "SSH should be disabled for production"
  }
}
```

## Running Tests Locally

### Prerequisites

```bash
# Terraform 1.6+ required
terraform --version

# Should output: Terraform v1.6.0 or higher
```

### Run All Tests for a Module

```bash
cd modules/aws-asg
terraform init -backend=false
terraform test
```

### Run All Tests for a Configuration

```bash
cd aws/gitlab-runner
terraform init -backend=false
terraform test
```

### Run Specific Test File

```bash
cd modules/aws-asg
terraform test tests/basic.tftest.hcl
```

### Run Tests with Verbose Output

```bash
terraform test -verbose
```

### Run Tests in Watch Mode (Development)

```bash
# Run tests whenever files change (requires entr)
ls *.tf tests/*.tftest.hcl | entr -c terraform test
```

## Writing Tests

### Test File Structure

```hcl
# tests/example.tftest.hcl

# Test run block with descriptive name
run "test_name_describing_what_is_tested" {
  # Command: plan (fast, no apply) or apply (slower, actually creates resources)
  command = plan

  # Variables for this test scenario
  variables {
    project_name = "test-project"
    enable_feature = true
    # ... all required variables
  }

  # Assertions to validate expected behavior
  assert {
    condition     = resource.type.name.attribute == expected_value
    error_message = "Descriptive error message explaining what failed"
  }

  assert {
    condition     = length(resource.type.name) > 0
    error_message = "Resource should be created"
  }
}
```

### Best Practices for Writing Tests

#### 1. Use Descriptive Names

```hcl
# ✅ GOOD: Clear, specific test names
run "validate_spot_instances_enabled_with_correct_price" { }
run "verify_ssh_disabled_by_default" { }
run "ensure_imdsv2_required_for_security" { }

# ❌ BAD: Vague test names
run "test1" { }
run "check_stuff" { }
run "validation" { }
```

#### 2. Test One Concept Per Run Block

```hcl
# ✅ GOOD: Each run block tests one specific aspect
run "validate_spot_configuration" {
  # Test only spot-related settings
}

run "validate_security_defaults" {
  # Test only security settings
}

# ❌ BAD: Testing multiple unrelated things
run "test_everything" {
  # Tests spot, security, networking, autoscaling all mixed together
}
```

#### 3. Provide Clear Error Messages

```hcl
# ✅ GOOD: Specific, actionable error messages
assert {
  condition     = var.min_instances >= 0
  error_message = "min_instances must be >= 0. Negative values are not supported."
}

# ❌ BAD: Vague error messages
assert {
  condition     = var.min_instances >= 0
  error_message = "Invalid value"
}
```

#### 4. Test Security Defaults

```hcl
run "validate_security_defaults" {
  command = plan

  variables {
    # Minimal required variables, rely on defaults
    project_name = "test"
    # ... other required variables
  }

  # Verify secure defaults
  assert {
    condition     = var.enable_ssh_access == false
    error_message = "SSH should be disabled by default"
  }

  assert {
    condition     = aws_launch_template.runner.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 should be required by default"
  }

  assert {
    condition     = length([for rule in aws_security_group.runner.ingress : rule if rule.cidr_blocks == ["0.0.0.0/0"]]) == 0
    error_message = "No security group rules should allow access from 0.0.0.0/0"
  }
}
```

#### 5. Test Cost Optimization

```hcl
run "validate_cost_optimization" {
  command = plan

  variables {
    use_spot_instances = true
    min_instances = 0  # Scale to zero
    disk_size = 32     # Minimal disk
    # ... other variables
  }

  assert {
    condition     = var.min_instances == 0
    error_message = "Should support scale-to-zero for cost optimization"
  }

  assert {
    condition     = var.use_spot_instances == true
    error_message = "Should use spot instances for cost savings"
  }
}
```

#### 6. Test Variable Validation

```hcl
run "validate_min_instances_constraint" {
  command = plan

  variables {
    min_instances = -1  # Invalid value
    # ... other variables
  }

  # Expect validation to fail
  expect_failures = [
    var.min_instances,
  ]
}

run "validate_min_less_than_max" {
  command = plan

  variables {
    min_instances = 10
    max_instances = 5  # Invalid: min > max
    # ... other variables
  }

  expect_failures = [
    var.max_instances,
  ]
}
```

## CI/CD Integration

### GitHub Actions Workflow

Tests run automatically on every push and pull request:

```yaml
jobs:
  terraform-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        test-dir:
          - modules/aws-asg
          - modules/azure-vmss
          - aws/gitlab-runner
          - azure/gitlab-runner
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ~1.9.0
      
      - name: Terraform Init
        run: terraform init -backend=false
        working-directory: ${{ matrix.test-dir }}
      
      - name: Run Tests
        run: terraform test -verbose
        working-directory: ${{ matrix.test-dir }}
```

### Pre-Commit Hook

Add tests to your pre-commit workflow:

```bash
#!/bin/bash
# .git/hooks/pre-commit

set -e

echo "Running Terraform tests..."

# Test modules
for dir in modules/*; do
  if [ -d "$dir/tests" ]; then
    echo "Testing $dir..."
    (cd "$dir" && terraform test)
  fi
done

# Test configurations
for dir in aws/* azure/*; do
  if [ -d "$dir/tests" ]; then
    echo "Testing $dir..."
    (cd "$dir" && terraform test)
  fi
done

echo "✅ All tests passed"
```

## Test Coverage

### What Should Be Tested

#### ✅ Must Test

1. **Security Defaults**
   - SSH disabled by default
   - IMDSv2 enabled (AWS)
   - Managed identity enabled (Azure)
   - No public IPs by default
   - Encryption enabled
   - Security groups/NSGs properly configured

2. **Variable Validation**
   - Required variables present
   - Constraints enforced (min/max values, patterns)
   - Invalid values rejected

3. **Cost Optimization**
   - Spot instance configuration
   - Scale-to-zero capability
   - Disk size optimization
   - Resource tagging

4. **Autoscaling**
   - Min/max/default instance counts
   - Scaling thresholds
   - Cooldown periods

#### ✅ Should Test

1. **Network Configuration**
   - VPC/VNet creation
   - Subnet configuration
   - Security group/NSG rules
   - Network isolation

2. **High Availability**
   - Multiple availability zones (when configured)
   - Proper instance distribution
   - Health checks

3. **Integration Points**
   - Runner registration configuration
   - Container image settings
   - User-data/cloud-init validation

#### ⚠️ Optional Tests

1. **Performance Optimization**
   - Accelerated networking (Azure)
   - Enhanced networking (AWS)
   - Disk IOPS configuration

2. **Monitoring**
   - CloudWatch/Azure Monitor configuration
   - Log Analytics integration

### Current Test Coverage

| Component | Unit Tests | Integration Tests | Coverage |
|-----------|------------|-------------------|----------|
| AWS ASG Module | ✅ | N/A | 85% |
| Azure VMSS Module | ✅ | N/A | 85% |
| AWS GitLab Runner | N/A | ✅ | 80% |
| Azure GitLab Runner | N/A | ✅ | 80% |
| AWS GitHub Runner | ⚠️ Pending | ⚠️ Pending | 0% |
| Azure GitHub Runner | ⚠️ Pending | ⚠️ Pending | 0% |
| AWS Azure DevOps Agent | ⚠️ Pending | ⚠️ Pending | 0% |
| Azure Azure DevOps Agent | ⚠️ Pending | ⚠️ Pending | 0% |

## Troubleshooting

### Common Issues

#### 1. Test Fails Due to Missing Variables

**Error**:
```
Error: Missing required argument
The argument "xxx" is required, but no definition was found.
```

**Solution**: Ensure all required variables are provided in the test's `variables` block:

```hcl
run "test_name" {
  command = plan
  
  variables {
    # Add ALL required variables
    project_name = "test"
    region = "us-east-1"
    # ... etc
  }
}
```

#### 2. Assertion Fails Due to Conditional Resources

**Error**:
```
Error: Invalid reference
A reference to a resource that has not been created
```

**Solution**: Use conditional logic in assertions:

```hcl
assert {
  condition = (
    var.enable_feature ? 
    resource.type.name[0].attribute == "value" : 
    true
  )
  error_message = "When feature is enabled, attribute should be 'value'"
}

# Or use can() for safer checks
assert {
  condition = (
    can(resource.type.name[0].attribute) ? 
    resource.type.name[0].attribute == "value" : 
    true
  )
  error_message = "Attribute check failed"
}
```

#### 3. Tests Pass Locally But Fail in CI

**Possible causes**:
- Different Terraform versions
- Missing provider initialization
- Backend configuration issues

**Solution**:
```bash
# Ensure consistent Terraform version
terraform version

# Initialize without backend
terraform init -backend=false

# Run tests with verbose output
terraform test -verbose
```

#### 4. Slow Test Execution

**Issue**: Tests taking too long to run

**Solution**:
- Use `command = plan` instead of `apply` (much faster)
- Only use `apply` when you need to test actual resource creation
- Parallelize test execution in CI/CD

## Performance Comparison

### Terraform Test vs LocalStack vs Real Cloud

| Approach | Setup Time | Test Execution | Cost | Cloud Support |
|----------|-----------|----------------|------|---------------|
| **Terraform Test (plan)** | 0s | 2-5s per test | $0 | AWS, Azure, GCP |
| **LocalStack** | 30-60s | 10-30s per test | $0 (limited), $49+/mo (full) | AWS only |
| **Real Cloud (ephemeral)** | 60-300s | 5-15 min per test | $0.10-1.00 per test | All clouds |
| **Real Cloud (persistent)** | 300-900s (first time) | 2-10 min per test | Ongoing costs | All clouds |

**Recommendation**: Use Terraform Test for 95% of validation. Only deploy to real cloud for:
- End-to-end integration testing
- Pre-production validation
- Testing provider-specific behavior
- Performance testing

## Advanced Testing Patterns

### Testing Multiple Scenarios

```hcl
# Test matrix of configurations
locals {
  test_scenarios = {
    development = {
      instance_type = "t3.micro"
      use_spot = true
      min_instances = 0
    }
    production = {
      instance_type = "t3.large"
      use_spot = false
      min_instances = 2
    }
  }
}

run "validate_development_config" {
  command = plan
  
  variables = merge(
    local.base_variables,
    local.test_scenarios.development
  )
  
  assert {
    condition     = var.use_spot == true
    error_message = "Development should use spot instances"
  }
}

run "validate_production_config" {
  command = plan
  
  variables = merge(
    local.base_variables,
    local.test_scenarios.production
  )
  
  assert {
    condition     = var.min_instances >= 2
    error_message = "Production should have at least 2 instances"
  }
}
```

### Testing with Mock Modules

```hcl
# Override module sources for testing
run "test_with_mock_network" {
  command = plan
  
  override_module {
    target = module.network
    outputs = {
      vpc_id = "vpc-mock123"
      subnet_ids = ["subnet-mock1", "subnet-mock2"]
    }
  }
  
  variables {
    # Use mocked network outputs
  }
}
```

## Next Steps

1. **Expand Coverage**: Add tests for GitHub Runner and Azure DevOps Agent configurations
2. **E2E Testing**: Consider adding end-to-end tests with real cloud resources (optional)
3. **Performance Tests**: Add tests for runner performance and scaling behavior
4. **Chaos Testing**: Test failure scenarios (spot termination, network issues)

## Resources

- [Terraform Test Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Project TESTING_GUIDE.md](../TESTING_GUIDE.md) - Manual testing procedures
- [GitHub Actions Workflow](.github/workflows/terraform-validation.yml) - CI/CD setup
- [AWS Provider Testing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Azure Provider Testing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

**Remember**: Tests are code too. Keep them maintainable, readable, and focused. Good tests give you confidence to make changes quickly and safely.
