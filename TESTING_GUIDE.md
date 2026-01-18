# Testing Guide

## Overview

Validation procedures for self-hosted runner infrastructure.

**Automated Testing:** See [docs/TERRAFORM_TESTING.md](docs/TERRAFORM_TESTING.md) for Terraform native test framework details.

## Prerequisites

- Terraform >= 1.5.0
- Cloud CLI authenticated
- Test CI/CD account with permissions
- Docker (for local testing)

## Test Types

### 1. Configuration Validation

```bash
# Validate all modules
for dir in modules/*/; do
  cd "$dir" && terraform init -backend=false && terraform validate && cd - > /dev/null
done

# Validate implementations
for dir in azure/*/ aws/*/; do
  cd "$dir" && terraform init -backend=false && terraform validate && cd - > /dev/null
done

# Or use script
./scripts/run-tests.sh
```

### 2. Module Unit Tests

```bash
# Test specific module
cd modules/aws-asg
terraform init -backend=false
terraform test

# Test with coverage
cd modules/azure-vmss
terraform init -backend=false
terraform test
```

### 3. Integration Testing

#### Deploy Test Environment

```bash
cd azure/gitlab-runner  # or aws/gitlab-runner

# Minimal test configuration
cat > terraform.tfvars << EOF
project_name          = "test-runner"
gitlab_url            = "https://gitlab.com"
gitlab_token          = "$GITLAB_TEST_TOKEN"
use_spot_instances    = true
min_instances         = 0
max_instances         = 2
EOF

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

#### Verify Deployment

**Check instances:**
```bash
# Azure
az vmss list-instances --resource-group test-runner-rg --name test-runner-vmss --output table

# AWS
aws autoscaling describe-auto-scaling-instances --output table
```

**Check runner registration:**
- GitLab: Settings → CI/CD → Runners
- GitHub: Settings → Actions → Runners
- Azure DevOps: Organization Settings → Agent pools

#### Test Job Execution

**GitLab (.gitlab-ci.yml):**
```yaml
test-job:
  tags: [docker, linux]
  script:
    - echo "Testing runner"
    - docker --version
    - nproc
```

**GitHub (.github/workflows/test.yml):**
```yaml
name: Test Runner
on: [push]
jobs:
  test:
    runs-on: [self-hosted, linux, x64]
    steps:
      - run: |
          echo "Testing runner"
          docker --version
          nproc
```

#### Test Autoscaling

```bash
# Trigger multiple jobs, monitor scaling
watch -n 10 'az vmss list-instances --resource-group test-runner-rg --name test-runner-vmss --output table'

# Or AWS
watch -n 10 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names test-runner-asg'
```

#### Test Scale-to-Zero

Wait 15-20 minutes after jobs complete, verify instances terminate:

```bash
# Azure
az vmss list-instances --resource-group test-runner-rg --name test-runner-vmss --output table

# AWS
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names test-runner-asg --query "AutoScalingGroups[0].Instances"
```

#### Test Spot Termination

**Azure:**
```bash
# Terminate instance, check graceful shutdown
az vmss delete-instances --resource-group test-runner-rg --name test-runner-vmss --instance-ids 0

# Check logs
az vmss run-command invoke --resource-group test-runner-rg --name test-runner-vmss \
  --command-id RunShellScript --scripts "tail -n 50 /var/log/vmss_monitor.log"
```

**AWS:**
```bash
# Terminate via console or CLI
aws ec2 terminate-instances --instance-ids <instance-id>

# Check logs via Session Manager
aws ssm start-session --target <instance-id>
sudo tail -f /var/log/spot_monitor.log
```

#### Cleanup

```bash
terraform destroy -auto-approve
```

## Validation Checklist

### Pre-Deployment
- [ ] Terraform validation passes
- [ ] Security defaults verified (SSH disabled, encryption enabled)
- [ ] Cost estimates reviewed
- [ ] Spot instances configured

### Post-Deployment
- [ ] Runners register successfully
- [ ] Test job executes
- [ ] Autoscaling works (scale up)
- [ ] Scale-to-zero works (scale down)
- [ ] Spot termination handles gracefully
- [ ] Logs accessible

### Production Readiness
- [ ] Production features configured (cache, logging, monitoring)
- [ ] Security reviewed (see [SECURITY.md](SECURITY.md))
- [ ] Monitoring/alerts configured
- [ ] Documentation updated
- [ ] Backup/recovery tested

## Common Test Scenarios

### Scenario 1: Job Queue Handling

```bash
# Trigger 10 jobs simultaneously
for i in {1..10}; do
  # Trigger job via API or commit
  echo "Job $i triggered"
done

# Expected: Autoscaling adds instances to handle load
# Verify: Check instance count increases
```

### Scenario 2: Cost Optimization

```bash
# Deploy with spot instances
use_spot_instances = true
min_instances      = 0

# Expected: Instances use spot pricing
# Expected: Scales to zero when idle
# Verify: Check billing after 24 hours
```

### Scenario 3: High Availability

```bash
# Configure multiple zones
zones = ["1", "2", "3"]
min_instances = 3

# Terminate instance in one zone
# Expected: Job continues on instances in other zones
# Verify: Job doesn't fail
```

### Scenario 4: Network Isolation

```bash
# Deploy in private subnet
associate_public_ip_address = false  # AWS

# Expected: Instances accessible via Session Manager (AWS) or Bastion (Azure)
# Expected: Outbound internet works via NAT Gateway
# Verify: Runner can pull Docker images, packages
```

## Performance Testing

### Job Execution Time

```bash
# Run same job on self-hosted vs cloud runners
# Compare execution times

# Expected: Self-hosted similar or faster (no queue time)
```

### Disk I/O

```bash
# Test in job:
dd if=/dev/zero of=testfile bs=1G count=1 oflag=direct

# Compare disk types:
# StandardSSD_LRS (Azure) vs gp3 (AWS)
# Premium_LRS (Azure) vs gp3 w/ higher IOPS (AWS)
```

### Network Throughput

```bash
# Test in job:
wget -O /dev/null http://speedtest.ftp.otenet.gr/files/test10Mb.db

# Compare between regions/zones
```

## Troubleshooting Tests

### Runners Not Registering

```bash
# Check initialization logs
# Azure
az vmss run-command invoke --resource-group <rg> --name <vmss> \
  --command-id RunShellScript --scripts "cat /var/log/cloud-init-output.log"

# AWS
aws ssm start-session --target <instance-id>
sudo cat /var/log/user-data.log
```

### Autoscaling Not Working

```bash
# Check autoscale settings
# Azure
az monitor autoscale show --resource-group <rg> --name <vmss>-autoscale

# AWS
aws autoscaling describe-policies --auto-scaling-group-name <asg>

# Check metrics
# Azure
az monitor metrics list --resource <vmss-id> --metric "Percentage CPU"

# AWS
aws cloudwatch get-metric-statistics --namespace AWS/EC2 \
  --metric-name CPUUtilization --dimensions Name=AutoScalingGroupName,Value=<asg>
```

## Continuous Testing

### CI/CD Integration

Run tests automatically on changes:

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
      - name: Terraform Validate
        run: |
          for dir in modules/*/ azure/*/ aws/*/; do
            cd $dir
            terraform init -backend=false
            terraform validate
            cd -
          done
      - name: Terraform Test
        run: ./scripts/run-tests.sh
```

## Load Testing

### Stress Test Autoscaling

```bash
# Configure aggressive autoscaling
cpu_scale_out_threshold = 50
max_instances          = 20

# Trigger many concurrent jobs (100+)
# Monitor:
# - Instance count
# - Job queue depth
# - CPU utilization
# - Scale up/down timing
```

## References

- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [docs/TERRAFORM_TESTING.md](docs/TERRAFORM_TESTING.MD) - Framework details
- [QUICKSTART.md](QUICKSTART.md) - Deployment procedures
- [SECURITY.md](SECURITY.md) - Security validation
