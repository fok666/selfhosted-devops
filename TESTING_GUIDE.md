# Production Testing Guide

## Overview

This guide provides comprehensive testing procedures for validating self-hosted DevOps runner infrastructure before production deployment.

**✅ Automated Testing**: All GitLab Runner implementations include automated Terraform tests. See [TERRAFORM_TESTING.md](docs/TERRAFORM_TESTING.md) for details on the native Terraform test framework.

## Testing Environment Requirements

### Prerequisites
- Terraform >= 1.5.0
- Azure CLI (for Azure deployments)
- AWS CLI (for AWS deployments)
- Docker (for local testing)
- jq (for JSON parsing)
- Test CI/CD account with permissions

## Test Levels

### 1. Syntax & Configuration Testing

#### Terraform Validation
```bash
# Test all modules
for dir in modules/*/; do
  echo "Testing $dir"
  cd "$dir"
  terraform init
  terraform validate
  cd - > /dev/null
done

# Test all implementations
for dir in azure/*/ aws/*/; do
  echo "Testing $dir"
  cd "$dir"
  terraform init
  terraform validate
  cd - > /dev/null
done
```

#### Expected Output
```
Success! The configuration is valid.
```

### 2. Unit Testing

#### Module Testing
```bash
# Test Azure VMSS module
cd modules/azure-vmss
terraform init
terraform validate
terraform fmt -check

# Test AWS ASG module
cd modules/aws-asg
terraform init
terraform validate
terraform fmt -check
```

### 3. Integration Testing

#### Test Deployment Workflow

**Step 1: Deploy to Test Environment**
```bash
cd azure/gitlab-runner  # or any implementation

# Create test tfvars
cat > terraform.tfvars << EOF
project_name          = "test-runner"
location              = "East US"
gitlab_url            = "https://gitlab.com"
gitlab_token          = "$GITLAB_TEST_TOKEN"

# Use defaults optimized for cost
use_spot_instances    = true
min_instances         = 0
max_instances         = 2
default_instances     = 1

# Defaults (can be omitted, shown for reference)
# vm_sku                    = "Standard_D2s_v3"
# os_disk_size_gb           = 64
# os_disk_type              = "StandardSSD_LRS"
# runner_count_per_instance = 0  # Auto-detect
# vnet_address_space        = "10.0.0.0/16"
EOF

# Deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Step 2: Verify Runner Registration**
```bash
# Wait for deployment
sleep 180

# Check GitLab/GitHub/Azure DevOps for registered runners
# Azure: Check VMSS instances
az vmss list-instances \
  --resource-group test-runner-rg \
  --name test-runner-gitlab-runner \
  --output table

# AWS: Check ASG instances
aws autoscaling describe-auto-scaling-instances \
  --output table
```

**Step 3: Test CI/CD Job Execution**
```yaml
# .gitlab-ci.yml (for GitLab)
test-job:
  tags:
    - docker
    - linux
  script:
    - echo "Testing self-hosted runner"
    - docker --version
    - uname -a
    - nproc
```

```yaml
# .github/workflows/test.yml (for GitHub)
name: Test Self-Hosted Runner
on: [push]
jobs:
  test:
    runs-on: [self-hosted, linux, x64]
    steps:
      - name: Test runner
        run: |
          echo "Testing self-hosted runner"
          docker --version
          uname -a
          nproc
```

**Step 4: Test Autoscaling**
```bash
# Trigger multiple jobs simultaneously
for i in {1..5}; do
  # Trigger CI/CD job
  echo "Triggering job $i"
done

# Watch scaling
watch -n 10 'az vmss list-instances --resource-group test-runner-rg --name test-runner-gitlab-runner --output table'
# or
watch -n 10 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names test-runner-gitlab-runner --query "AutoScalingGroups[0].Instances" --output table'
```

**Step 5: Test Scale to Zero**
```bash
# Wait for jobs to complete
# Wait 15-20 minutes

# Verify instances terminate
az vmss list-instances \
  --resource-group test-runner-rg \
  --name test-runner-gitlab-runner \
  --output table | wc -l
```

**Step 6: Test Spot Termination**
```bash
# SSH into instance
ssh -i runner-key.pem azureuser@<instance-ip>

# Or AWS Session Manager
aws ssm start-session --target <instance-id>

# Check monitoring logs
sudo tail -f /var/log/vmss_monitor.log  # Azure
sudo tail -f /var/log/ec2_monitor.log   # AWS

# Manually trigger termination (Azure)
az vmss delete-instances \
  --resource-group test-runner-rg \
  --name test-runner-gitlab-runner \
  --instance-ids 0

# AWS: Terminate spot instance via console
# Verify graceful shutdown in logs
```

**Step 7: Cleanup**
```bash
terraform destroy -auto-approve
```

### 4. Security Testing

#### Network Security Audit
```bash
# Azure: Check NSG rules
az network nsg show \
  --resource-group test-runner-rg \
  --name test-runner-nsg \
  --query "securityRules[*].{Name:name, Priority:priority, Direction:direction, Access:access}" \
  --output table

# AWS: Check security group rules
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=test-runner-runner-sg" \
  --query "SecurityGroups[*].{GroupId:GroupId, IpPermissions:IpPermissions}" \
  --output json
```

#### IAM/RBAC Audit
```bash
# Azure: Check managed identity permissions
az role assignment list \
  --assignee <principal-id> \
  --output table

# AWS: Check IAM role policies
aws iam list-attached-role-policies \
  --role-name test-runner-runner-role
```

#### Secrets Audit
```bash
# Ensure no hardcoded secrets
grep -r "glrt-" . --exclude-dir=.terraform --exclude-dir=.git
grep -r "ghp_" . --exclude-dir=.terraform --exclude-dir=.git
grep -r "password" . --exclude-dir=.terraform --exclude-dir=.git
```

### 5. Performance Testing

#### Startup Time Test
```bash
#!/bin/bash
# test-startup-time.sh

START_TIME=$(date +%s)

# Trigger scale up
# (trigger CI/CD job)

# Wait for runner to be ready
while ! curl -s http://runner-endpoint/health > /dev/null; do
  sleep 5
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "Startup time: $DURATION seconds"
```

#### Load Testing
```bash
# Trigger 20 concurrent jobs
for i in {1..20}; do
  # Trigger CI/CD job in background
  curl -X POST "..." &
done

# Monitor autoscaling
watch -n 5 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names test-runner --query "AutoScalingGroups[0].{Desired:DesiredCapacity,Current:Instances|length(@),Min:MinSize,Max:MaxSize}"'
```

### 6. Disaster Recovery Testing

#### Complete Infrastructure Recreation
```bash
# Destroy everything
terraform destroy -auto-approve

# Recreate from code
terraform init
terraform apply -auto-approve

# Verify runners register
# Run test job
```

#### State Recovery Test
```bash
# Backup state
terraform state pull > backup.tfstate

# Simulate corruption
rm terraform.tfstate

# Restore
terraform state push backup.tfstate

# Verify
terraform plan  # Should show no changes
```

## Test Results Documentation

### Test Report Template
```markdown
# Test Report: [Implementation Name]
**Date:** YYYY-MM-DD  
**Tester:** [Name]  
**Environment:** [Test/Staging/Production]

## Test Summary
- **Total Tests:** X
- **Passed:** X
- **Failed:** X
- **Skipped:** X

## Detailed Results

### Terraform Validation
- [ ] Module validation: PASS/FAIL
- [ ] Implementation validation: PASS/FAIL
- [ ] Syntax check: PASS/FAIL

### Integration Tests
- [ ] Deployment: PASS/FAIL
- [ ] Runner registration: PASS/FAIL
- [ ] Job execution: PASS/FAIL
- [ ] Autoscaling: PASS/FAIL
- [ ] Scale to zero: PASS/FAIL
- [ ] Spot termination: PASS/FAIL

### Security Tests
- [ ] Network security: PASS/FAIL
- [ ] IAM/RBAC: PASS/FAIL
- [ ] No hardcoded secrets: PASS/FAIL

### Performance Tests
- [ ] Startup time: X seconds (target: <180s)
- [ ] Scale up time: X minutes (target: <5min)
- [ ] Load handling: PASS/FAIL

## Issues Found
1. [Issue description]
   - Severity: High/Medium/Low
   - Status: Open/Fixed
   - Fix: [Description]

## Recommendations
1. [Recommendation]

## Sign-off
- Tested by: [Name]
- Approved by: [Name]
- Date: YYYY-MM-DD
```

## Automated Testing Script

```bash
#!/bin/bash
# run-tests.sh - Automated testing script

set -e

REPORT_FILE="test-report-$(date +%Y%m%d-%H%M%S).md"

echo "# Automated Test Report" > "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Function to run test and log result
run_test() {
  local test_name="$1"
  local test_command="$2"
  
  echo "Running: $test_name"
  echo "## Test: $test_name" >> "$REPORT_FILE"
  
  if eval "$test_command"; then
    echo "- ✅ PASSED" >> "$REPORT_FILE"
    echo "PASSED"
  else
    echo "- ❌ FAILED" >> "$REPORT_FILE"
    echo "FAILED"
    return 1
  fi
  echo "" >> "$REPORT_FILE"
}

# Run all tests
echo "=== Starting Automated Tests ==="

run_test "Terraform Format Check" "terraform fmt -check -recursive"
run_test "Azure VMSS Module Validation" "cd modules/azure-vmss && terraform init && terraform validate"
run_test "AWS ASG Module Validation" "cd modules/aws-asg && terraform init && terraform validate"

# Add more tests...

echo "=== Tests Complete ==="
echo "Report saved to: $REPORT_FILE"
```

## Continuous Testing

### Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run terraform fmt
terraform fmt -recursive

# Run validation
for dir in modules/*/ azure/*/ aws/*/; do
  if [ -f "$dir/main.tf" ]; then
    echo "Validating $dir"
    (cd "$dir" && terraform init -backend=false && terraform validate)
  fi
done
```

### CI/CD Pipeline
```yaml
# .github/workflows/terraform-test.yml
name: Terraform Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Format
        run: terraform fmt -check -recursive
      
      - name: Validate Modules
        run: |
          for dir in modules/*/; do
            cd "$dir"
            terraform init -backend=false
            terraform validate
            cd -
          done
```

## Performance Benchmarks

### Expected Performance Metrics

| Metric | Target | Warning | Critical | Notes |
|--------|--------|---------|----------|-------|
| Startup Time | <180s | 180-300s | >300s | From scale-up to job start |
| Scale Up Response | <5min | 5-10min | >10min | VM provision + runner registration |
| Scale Down Response | <15min | 15-25min | >25min | After jobs complete |
| Job Queue Time | <60s | 60-180s | >180s | With available capacity |
| Spot Interruption Recovery | <5min | 5-10min | >10min | Auto-replacement time |
| Disk I/O (StandardSSD) | 500 IOPS | 300-500 | <300 | 64GB disk baseline |
| Disk I/O (Premium) | 120 IOPS/GB | 80-120 | <80 | Performance tier |

### Performance Tuning Options

**To improve startup time:**
- Use Premium_LRS disks (+2-3x IOPS, +$5/mo)
- Pre-warm instances (set min_instances > 0)
- Use larger VM sizes for faster provisioning

**To improve build speed:**
- Increase disk size for better caching
- Use compute-optimized VMs (F-series)
- Set runner_count_per_instance = 1 for dedicated resources

## Troubleshooting Test Failures

### Common Issues

**Terraform Init Fails**
```bash
# Clear cache
rm -rf .terraform .terraform.lock.hcl
terraform init
```

**Runner Not Registering**
```bash
# Check logs
sudo cat /var/log/gitlab-runner-init.log
docker ps -a | grep runner
docker logs <container-name>

# Check network
curl -I $RUNNER_URL
```

**Autoscaling Not Working**
```bash
# Check CPU metrics
# Azure
az monitor metrics list --resource <vmss-id> --metric "Percentage CPU"

# AWS
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=<asg-name> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## Test Sign-off Checklist

Before approving for production:

- [ ] All Terraform configurations validate successfully
- [ ] Successful deployment to test environment
- [ ] Runners register correctly on all platforms
- [ ] Test jobs execute successfully
- [ ] Autoscaling works as expected
- [ ] Scale-to-zero functions correctly
- [ ] Spot termination handled gracefully
- [ ] Security audit passed
- [ ] Performance benchmarks met
- [ ] Documentation reviewed and accurate
- [ ] Cost estimates validated
- [ ] Rollback procedure tested
- [ ] Monitoring and alerts configured
- [ ] Team trained on operations

---

**Ready for Production:** ✅ / ❌  
**Approved By:** _________________  
**Date:** _________________
