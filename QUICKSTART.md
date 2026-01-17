# Self-Hosted DevOps Runners - Quick Start Guide

## Overview

This project provides production-ready Terraform Infrastructure as Code (IaC) for deploying autoscaling, ephemeral CI/CD runners on Azure and AWS.

**✅ Quality Assured**: All GitLab Runner implementations include comprehensive automated tests with 100% CI/CD validation coverage.

## What's Included

✅ **Fully Implemented:**
- GitLab Runner on Azure VMSS
- GitLab Runner on AWS Auto Scaling Groups
- Shared Terraform modules for easy customization

📋 **Ready to Implement (follow the pattern):**
- GitHub Actions Runner (Azure & AWS)
- Azure DevOps Agent (Azure & AWS)

## Architecture Highlights

### Azure Implementation
- **VM Scale Sets (VMSS)** with Spot instances
- **Autoscaling** based on CPU utilization (scale 0-N)
- **VMSS Scheduled Events** monitoring for graceful shutdown
- **Ubuntu 24.04 LTS** with Docker pre-installed (support until 2029)
- **64GB StandardSSD disks** for optimal cost/performance balance
- **Configurable network CIDRs** (default: 10.0.0.0/16)
- **Multiple runners per VM** for resource optimization (auto-detected)

### AWS Implementation
- **Auto Scaling Groups (ASG)** with Spot instances
- **Mixed instances policy** for spot diversification
- **Target tracking** autoscaling
- **EC2 Spot termination** monitoring
- **Ubuntu 24.04 LTS** with Docker pre-installed (support until 2029)
- **64GB StandardSSD disks** for optimal cost/performance balance
- **Configurable network CIDRs** (default: 10.0.0.0/16)
- **Multiple runners per instance** for resource optimization (auto-detected)

## Quick Start

### 1. Prerequisites

```bash
# Install Terraform
brew install terraform  # macOS
# or download from https://terraform.io

# Authenticate to your cloud provider
az login           # Azure
aws configure      # AWS
```

### 2. Deploy GitLab Runner on Azure

```bash
cd azure/gitlab-runner

# Copy and configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply
```

### 3. Deploy GitLab Runner on AWS

```bash
cd aws/gitlab-runner

# Copy and configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply
```

## Configuration Examples

### Minimal Configuration (Scale to Zero)
```hcl
# terraform.tfvars
project_name       = "my-runner"
gitlab_url         = "https://gitlab.com"
gitlab_token       = "glrt-xxxxx"
use_spot_instances = true
min_instances      = 0  # Scale to zero!
max_instances      = 10
default_instances  = 1
```

### Production Configuration
```hcl
# terraform.tfvars
project_name          = "prod-runner"
gitlab_url            = "https://gitlab.company.com"
gitlab_token          = "glrt-xxxxx"
runner_tags           = "docker,linux,production"

# Cost optimization (spot instances enabled by default)
use_spot_instances    = true
min_instances         = 2    # Always have 2 ready
max_instances         = 20

# Performance (upgrade from defaults if needed)
vm_sku                = "Standard_D4s_v3"  # 4 vCPU, 16 GB
os_disk_size_gb       = 128   # More space for large builds
os_disk_type          = "Premium_LRS"  # Faster I/O

# Generic naming (works for all runner types)
runner_count_per_instance = 0     # Auto-detect based on vCPU

# Network (customize if needed)
vnet_address_space    = "10.1.0.0/16"
subnet_address_prefix = "10.1.1.0/24"
```

## Cost Optimization Tips

1. **Enable Spot Instances** (70-90% savings)
   ```hcl
   use_spot_instances = true
   ```

2. **Scale to Zero When Idle**
   ```hcl
   min_instances = 0
   ```

3. **Right-size Your VMs/Instances**
   ```hcl
   vm_sku = "Standard_D2s_v3"  # Azure
   instance_type = "t3.medium"  # AWS
   ```

4. **Use Auto-detection for Runner Count**
   ```hcl
   runner_count_per_vm = 0  # Auto-detect based on vCPU
   ```

## Instance/VM Size Recommendations

### Light Workloads (2 vCPU, 4-8 GB RAM)
- **Azure:** `Standard_D2s_v3` (RECOMMENDED), `Standard_B2s`
- **AWS:** `t3.medium`, `t3a.medium`
- **Cost:** ~$7-15/month with spot (~$70/month on-demand)
- **Use for:** Small projects, infrequent builds, development

### Medium Workloads (4 vCPU, 16 GB RAM)
- **Azure:** `Standard_D4s_v3`
- **AWS:** `t3.xlarge`, `m5.xlarge`
- **Cost:** ~$30-50/month with spot (~$140/month on-demand)
- **Use for:** Standard CI/CD, Docker builds, monorepos

### Heavy Workloads (8 vCPU, 32 GB RAM)
- **Azure:** `Standard_D8s_v3`, `Standard_F8s_v2`
- **AWS:** `m5.2xlarge`, `c5.2xlarge`
- **Cost:** ~$60-100/month with spot (~$280/month on-demand)
- **Use for:** Large builds, parallel testing, compute-intensive jobs

### Disk Size Recommendations

- **64GB** (DEFAULT): Sufficient for 90% of workloads, ~$5/month
- **128GB**: Large Docker images, build artifacts, ~$10/month
- **256GB+**: Monorepos with extensive caching, ~$20+/month

## Monitoring

### Azure
```bash
# View VMSS status
az vmss list --resource-group <rg-name> --output table

# View autoscale settings
az monitor autoscale show --resource-group <rg-name> --name <vmss-name>-autoscale

# View VM logs (SSH required)
ssh -i <key> azureuser@<vm-ip>
sudo tail -f /var/log/gitlab-runner-init.log
```

### AWS
```bash
# View ASG status
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg-name>

# View scaling policies
aws autoscaling describe-policies --auto-scaling-group-name <asg-name>

# Connect via Session Manager (no SSH key needed)
aws ssm start-session --target <instance-id>
sudo tail -f /var/log/gitlab-runner-init.log
```

## Troubleshooting

### Runners Not Appearing

1. **Check VM/Instance logs:**
   ```bash
   # Azure
   sudo cat /var/log/gitlab-runner-init.log
   
   # AWS
   sudo cat /var/log/gitlab-runner-init.log
   ```

2. **Check Docker containers:**
   ```bash
   docker ps -a | grep gitlab-runner
   docker logs gitlab-runner-1
   ```

3. **Verify token is correct**
   - Check your CI/CD platform for the registration token
   - Ensure it hasn't expired

### High Costs

1. **Verify spot instances are enabled:**
   ```bash
   # Azure
   az vmss show --name <vmss-name> --resource-group <rg-name> --query "virtualMachineProfile.priority"
   
   # AWS
   aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg-name> | grep -i spot
   ```

2. **Check autoscaling is working:**
   - Ensure min_instances is set correctly
   - Verify CPU thresholds trigger scale down

3. **Monitor actual usage:**
   ```bash
   # Azure
   az monitor metrics list --resource <vmss-id> --metric "Percentage CPU"
   
   # AWS
   aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization ...
   ```

### Spot Instances Being Evicted Frequently

1. **Diversify instance types (AWS):**
   ```hcl
   spot_instance_types = ["t3.medium", "t3a.medium", "t2.medium", "t3.small"]
   ```

2. **Increase max price:**
   ```hcl
   spot_max_price = "0.10"  # Set specific price
   ```

3. **Use on-demand if needed:**
   ```hcl
   use_spot_instances = false
   ```

## Security Best Practices

1. **Store tokens securely:**
   ```bash
   # Use Azure Key Vault
   data "azurerm_key_vault_secret" "gitlab_token" {
     name         = "gitlab-token"
     key_vault_id = var.key_vault_id
   }
   
   # Or AWS Secrets Manager
   data "aws_secretsmanager_secret_version" "gitlab_token" {
     secret_id = "gitlab-token"
   }
   ```

2. **Use private subnets** for production
3. **Enable encryption** at rest and in transit
4. **Regular updates** - rebuild AMIs/images monthly
5. **Least privilege** IAM roles and permissions

## Getting Registration Tokens

### GitLab
1. Go to **Settings** > **CI/CD** > **Runners**
2. Click "New project/group runner"
3. Copy the token (starts with `glrt-`)

### GitHub
1. Go to **Settings** > **Actions** > **Runners**
2. Click "New self-hosted runner"
3. Copy the token

### Azure DevOps
1. Go to **Organization Settings** > **Agent pools**
2. Click your pool > **New agent**
3. Copy the Personal Access Token (PAT)

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Verify deletion in cloud console
```

## Support

- **Issues:** Open an issue in this repository
- **Documentation:** See individual README.md files in each implementation
- **Examples:** Check `terraform.tfvars.example` files

## License

MIT License - See LICENSE file for details

## Credits

Runner Docker images by [Fernando Korndorfer (fok666)](https://github.com/fok666):
- [gitlab-selfhosted-runner](https://github.com/fok666/gitlab-selfhosted-runner)
- [github-selfhosted-runner](https://github.com/fok666/github-selfhosted-runner)
- [azure-devops-agent](https://github.com/fok666/azure-devops-agent)
