# Self-Hosted DevOps Runners - Quick Start Guide

## 🚀 Choose Your Path

New to this project? Pick the path that matches your experience level:

### ⚡ Path 1: "Just Get It Running" (5 minutes)
**Best for:** First-time users, learning, testing

Use our interactive deployment script:
```bash
./scripts/quick-deploy.sh
```
The script will:
- Guide you through choosing cloud provider and configuration
- Collect required information (tokens, regions, etc.)
- Validate prerequisites automatically
- Deploy everything for you

**→ [Jump to Interactive Deploy](#interactive-deployment-easiest)**

---

### 🎯 Path 2: "I Want Preset Configs" (10 minutes)
**Best for:** Quick deployment with proven configurations

Choose a preset that matches your needs:
- **Minimal** → Testing, learning ($5-20/mo)
- **Development** → Small teams ($40-80/mo)
- **Production** → Business-critical ($150-300/mo)
- **High-Performance** → Enterprise ($500-1000/mo)

**→ [Jump to Preset Configurations](#preset-configurations-recommended)**

---

### 📚 Path 3: "I Want Full Control" (30 minutes)
**Best for:** Advanced users wanting to understand everything

Learn the architecture, customize every setting, and deploy manually.

**→ [Jump to Manual Deployment](#manual-deployment-advanced)**

---

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

---

## Interactive Deployment (Easiest)

### Prerequisites Check

Run the validation script first to ensure you have everything needed:

```bash
cd azure/gitlab-runner  # or aws/gitlab-runner
bash ../../scripts/validate-prerequisites.sh
```

This checks:
- ✅ Terraform installation and version
- ✅ Cloud CLI authentication (Azure or AWS)
- ✅ Network connectivity to CI/CD platforms
- ✅ Configuration file validity

### One-Command Deploy

From the project root, run:

```bash
./scripts/quick-deploy.sh
```

The interactive script will:
1. **Ask which cloud provider** (Azure or AWS)
2. **Ask which CI/CD platform** (GitLab, GitHub, Azure DevOps)
3. **Help choose configuration** (Minimal, Development, Production, High-Performance)
4. **Collect required info** (project name, tokens, region)
5. **Validate everything** automatically
6. **Deploy infrastructure** with one confirmation

**That's it!** Your runners will be deployed and ready to use.

---

## Preset Configurations (Recommended)

Choose a configuration that matches your needs, then deploy with minimal customization.

### 🔍 Which Configuration Should I Use?

| Your Situation | Recommended Config | Monthly Cost |
|----------------|-------------------|--------------|
| Just learning/testing | **Minimal** | $5-20 |
| Small team (1-10 devs) | **Development** | $40-80 |
| Medium team (10-50 devs) | **Production** | $150-300 |
| Large team (50+ devs) | **High-Performance** | $500-1000 |
| Very light usage | **Minimal** | $5-20 |
| Frequent builds | **Development** or **Production** | $40-300 |
| CPU-intensive workloads | **Production** or **High-Performance** | $150-1000 |

### 📦 Available Presets

All preset configurations are in the [`examples/`](examples/) directory:

- **[Minimal](examples/minimal/)** - Scale to zero, spot only, small VMs
- **[Development](examples/development/)** - 1 baseline instance, good for small teams
- **[Production](examples/production/)** - 2-3 baseline, high availability
- **[High-Performance](examples/high-performance/)** - Large VMs, premium storage, maximum capacity

### 🚀 Deploy with a Preset

#### Step 1: Copy the Preset

```bash
# Example: Deploy Production GitLab Runner on Azure
cd azure/gitlab-runner
cp ../../examples/production/azure-gitlab.tfvars terraform.tfvars
```

#### Step 2: Edit Required Values

Open `terraform.tfvars` and change these 3 lines:

```hcl
project_name = "my-runner"           # ← Your project name
gitlab_url   = "https://gitlab.com"  # ← Your GitLab URL
gitlab_token = "glrt-xxxxx"          # ← Your token (see below for where to get it)
```

**Where to get tokens:**
- **GitLab:** Settings → CI/CD → Runners → "New project runner"
- **GitHub:** Settings → Actions → Runners → "New self-hosted runner"
- **Azure DevOps:** Organization Settings → Agent pools → Create PAT

#### Step 3: Deploy

```bash
# Validate prerequisites first (optional but recommended)
bash ../../scripts/validate-prerequisites.sh

# Deploy
terraform init
terraform plan    # Review what will be created
terraform apply   # Deploy!
```

**Done!** Check your CI/CD platform to see your new runners.

---

## Manual Deployment (Advanced)

For full control and understanding of every setting.

### 1. Prerequisites

Install required tools:

```bash
# Install Terraform (>= 1.5.0)
brew install terraform  # macOS
# or download from https://terraform.io

# Authenticate to your cloud provider
az login           # Azure
aws configure      # AWS
```

Verify installation:
```bash
terraform version    # Should be >= 1.5.0
az account show      # For Azure
aws sts get-caller-identity  # For AWS
```

### 2. Choose Your Deployment

Navigate to the appropriate directory:

```bash
# GitLab Runner on Azure
cd azure/gitlab-runner

# GitLab Runner on AWS
cd aws/gitlab-runner

# GitHub Actions on Azure
cd azure/github-runner

# GitHub Actions on AWS
cd aws/github-runner

# Azure DevOps Agent on Azure
cd azure/azure-devops-agent

# Azure DevOps Agent on AWS
cd aws/azure-devops-agent
```

### 3. Create Configuration File

Copy the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values. See [Configuration Examples](#configuration-examples) below.

### 4. Deploy

```bash
# Initialize Terraform (downloads providers)
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply
```

Type `yes` when prompted to confirm deployment.

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

### ❌ Common Issues & Quick Fixes

#### Problem: "Runners not appearing in GitLab/GitHub/Azure DevOps"

**Symptom:** Terraform succeeds, but no runners show up in your CI/CD platform.

**Solutions:**

1. **Check token format:**
   ```bash
   # GitLab tokens should start with: glrt-
   # GitHub: ghp_
   # Azure DevOps: Check PAT hasn't expired
   ```

2. **Verify network connectivity:**
   ```bash
   # SSH into an instance and check logs
   # Azure
   az vmss list-instances --resource-group <rg> --name <vmss> --output table
   
   # AWS
   aws ec2 describe-instances --filters "Name=tag:Name,Values=<asg-name>*"
   ```

3. **Check cloud-init/user-data logs:**
   ```bash
   # On the VM/instance:
   sudo cat /var/log/cloud-init-output.log  # Azure
   sudo cat /var/log/user-data.log          # AWS
   sudo cat /var/log/gitlab-runner-init.log # Both
   ```

4. **Verify Docker is running:**
   ```bash
   # On the VM/instance:
   sudo systemctl status docker
   sudo docker ps -a | grep runner
   ```

**Common causes:**
- Token expired or incorrect format
- Firewall blocking outbound connections to CI/CD platform
- VM/instance not fully initialized yet (wait 5 minutes)
- Docker not started or crashed

---

#### Problem: "Costs higher than expected"

**Symptom:** Azure/AWS bill is significantly higher than estimates.

**Solutions:**

1. **Verify spot instances are enabled:**
   ```bash
   # Check terraform.tfvars
   grep use_spot_instances terraform.tfvars
   # Should show: use_spot_instances = true
   ```

2. **Check if autoscaling down:**
   ```bash
   # Azure
   az monitor autoscale show --resource-group <rg> --name <vmss>-autoscale
   
   # AWS
   aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg>
   ```

3. **Review actual instance count:**
   ```bash
   # Azure
   az vmss list-instances --resource-group <rg> --name <vmss> --output table
   
   # AWS
   aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg> --query "AutoScalingGroups[0].Instances"
   ```

4. **Check disk sizes:**
   ```bash
   # Review terraform.tfvars
   grep os_disk_size_gb terraform.tfvars
   # Default should be 64GB
   ```

**Cost optimization checklist:**
- [ ] `use_spot_instances = true`
- [ ] `min_instances = 0` (or low number)
- [ ] `os_disk_size_gb = 64` (unless you need more)
- [ ] `os_disk_type = "StandardSSD_LRS"` or `"gp3"`
- [ ] Review [examples/minimal/](examples/minimal/) for absolute minimum cost

---

#### Problem: "Spot instances being evicted frequently"

**Symptom:** Jobs failing due to instance terminations.

**Solutions:**

1. **Increase spot price (Azure):**
   ```hcl
   spot_max_price = 0.10  # Increase from default
   ```

2. **Diversify instance types (AWS):**
   ```hcl
   spot_instance_types = [
     "t3.medium",
     "t3a.medium",
     "t2.medium",
     "t3.small"
   ]
   ```

3. **Use on-demand instances (temporary):**
   ```hcl
   use_spot_instances = false
   ```

4. **Increase min instances:**
   ```hcl
   min_instances = 2  # Always have 2 running
   ```

---

#### Problem: "Terraform validation errors"

**Symptom:** `terraform validate` or `terraform plan` fails.

**Solutions:**

1. **Run prerequisites validator:**
   ```bash
   bash ../../scripts/validate-prerequisites.sh
   ```

2. **Check required variables:**
   ```bash
   # Ensure these are set in terraform.tfvars:
   grep -E "project_name|gitlab_token|gitlab_url" terraform.tfvars
   ```

3. **Verify Terraform version:**
   ```bash
   terraform version  # Should be >= 1.5.0
   ```

4. **Re-initialize:**
   ```bash
   rm -rf .terraform .terraform.lock.hcl
   terraform init
   ```

---

#### Problem: "Can't SSH into instances"

**Symptom:** Unable to connect to VMs for debugging.

**Solutions:**

**By design, SSH is disabled for security.** Use cloud-native alternatives:

**Azure:**
```bash
# Use Azure Bastion (if configured) or Serial Console
az serial-console connect --resource-group <rg> --name <vm-name>

# Or enable SSH temporarily (requires redeployment):
# In terraform.tfvars:
# enable_ssh = true
# ssh_cidr_blocks = ["YOUR_IP/32"]
```

**AWS:**
```bash
# Use Systems Manager Session Manager (no SSH key needed)
aws ssm start-session --target <instance-id>

# Or enable SSH temporarily (requires redeployment):
# In terraform.tfvars:
# enable_ssh = true
# ssh_cidr_blocks = ["YOUR_IP/32"]
```

**Better approach:** Check logs via cloud portal or cloud-init output.

---

#### Problem: "Scale down not working"

**Symptom:** Instances stay at max count even when idle.

**Solutions:**

1. **Check autoscaling thresholds:**
   ```bash
   # Azure
   az monitor autoscale show --resource-group <rg> --name <vmss>-autoscale
   ```

2. **Verify CPU is actually low:**
   ```bash
   # Azure
   az monitor metrics list --resource <vmss-id> --metric "Percentage CPU"
   
   # AWS
   aws cloudwatch get-metric-statistics \
     --namespace AWS/EC2 \
     --metric-name CPUUtilization \
     --dimensions Name=AutoScalingGroupName,Value=<asg-name> \
     --start-time <start> --end-time <end> \
     --period 300 --statistics Average
   ```

3. **Check cooldown periods:**
   - Default cooldown is 5-10 minutes
   - Wait longer to see if scale down occurs

4. **Review scale-in threshold:**
   ```hcl
   # Should be low enough to trigger
   cpu_scale_in_threshold = 30  # Scale in at 30% CPU
   ```

---

## Troubleshooting

### ❌ Common Issues & Quick Fixes

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
