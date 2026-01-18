# Self-Hosted DevOps Runner Infrastructure as Code

Terraform infrastructure for deploying autoscaling, ephemeral, cost-optimized CI/CD runners on Azure and AWS.

[![CodeQL](https://github.com/fok666/selfhosted-devops/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/fok666/selfhosted-devops/actions/workflows/github-code-scanning/codeql)
[![Dependabot Updates](https://github.com/fok666/selfhosted-devops/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/fok666/selfhosted-devops/actions/workflows/dependabot/dependabot-updates)
[![Pre-commit Checks](https://github.com/fok666/selfhosted-devops/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/fok666/selfhosted-devops/actions/workflows/pre-commit.yml)
[![Terraform Validation](https://github.com/fok666/selfhosted-devops/actions/workflows/terraform-validation.yml/badge.svg)](https://github.com/fok666/selfhosted-devops/actions/workflows/terraform-validation.yml)
[![Documentation](https://github.com/fok666/selfhosted-devops/actions/workflows/documentation.yml/badge.svg)](https://github.com/fok666/selfhosted-devops/actions/workflows/documentation.yml)

## Supported Runners

Choose the runner that matches your CI/CD platform:

| Platform | Status | Azure | AWS | Best For |
|----------|--------|-------|-----|----------|
| **[GitLab Runner](https://github.com/fok666/gitlab-selfhosted-runner)** | ✅ Production | ✅ | ✅ | GitLab CI/CD pipelines |
| **[GitHub Actions](https://github.com/fok666/github-selfhosted-runner)** | ✅ Production | ✅ | ✅ | GitHub repositories |
| **[Azure DevOps Agent](https://github.com/fok666/azure-devops-agent)** | ✅ Production | ✅ | ✅ | Microsoft ecosystem |

### Platform Comparison

| Feature | GitLab Runner | GitHub Actions | Azure DevOps |
|---------|---------------|----------------|--------------|
| **Registration** | Token (glrt-) | PAT + URL | PAT + Pool |
| **Setup Difficulty** | ⭐⭐ Easy | ⭐⭐ Easy | ⭐⭐⭐ Moderate |
| **Docker Support** | ✅ Native | ✅ Native | ✅ Native |
| **Concurrent Jobs** | ✅ Unlimited | ✅ Unlimited | ✅ Unlimited |
| **Autoscaling** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Cost Optimization** | ✅ Spot instances | ✅ Spot instances | ✅ Spot instances |

**New to self-hosted runners?** Start with GitLab Runner - it's the easiest to set up and test.

## Features

### Core Features

✅ **Autoscaling** - VMSS (Azure) and Auto Scaling Groups (AWS)  
✅ **Spot/Preemptible Instances** - Up to 90% cost savings  
✅ **Ephemeral Runners** - On-demand, self-configuring instances  
✅ **Docker-in-Docker (DinD)** - Full Docker support in privileged mode  
✅ **Configurable Sizing** - Flexible VM/instance types with cost guidance  
✅ **Ubuntu 24.04 LTS** - Latest stable OS with support until 2029  
✅ **Optimized Defaults** - 64GB disks, balanced for cost and performance  
✅ **Network Flexibility** - Configurable VNet/VPC CIDRs  
✅ **Graceful Shutdown** - Monitors termination events and stops runners cleanly  
✅ **Multi-Cloud** - Identical configurations for Azure and AWS  
✅ **Cost/Performance Documentation** - Clear tradeoffs for every configuration option

### Production-Ready Features ✨ NEW

✅ **Distributed Caching** - Azure Blob Storage / S3 cache for faster builds  
✅ **Centralized Logging** - Azure Log Analytics / CloudWatch integration  
✅ **Runner Monitoring** - Prometheus metrics for observability  
✅ **Webhook-Based Scaling** - GitHub Actions webhook triggers (responsive scaling)  
✅ **Enhanced Security** - IMDSv2, encrypted disks, least privilege IAM  
✅ **Comprehensive Testing** - Automated Terraform tests included

### Custom Docker Images 🐳 NEW

✅ **Multi-Architecture Support** - x86-64 (AMD64) and ARM64 (Graviton, Ampere Altra)  
✅ **Multiple Image Variants** - Minimal, language-specific, cloud-native, and full toolchain  
✅ **Cost-Optimized Images** - Choose the right capabilities for your workload  
✅ **Production-Ready** - Security-scanned, signed, and regularly updated  

📦 **See [DOCKER_IMAGES.md](DOCKER_IMAGES.md) for complete image documentation, variant comparison, and cost analysis.**

📐 **See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture diagrams and explanations.**

## Documentation

- 📐 **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture diagrams and explanations with Mermaid diagrams
- 🚀 **[QUICKSTART.md](QUICKSTART.md)** - Quick deployment guide with examples
- � **[DOCKER_IMAGES.md](DOCKER_IMAGES.md)** - Docker image variants, multi-arch support, and cost comparison
- �🔒 **[SECURITY.md](SECURITY.md)** - Security best practices and default configurations
- 🧪 **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Manual testing procedures and validation
- ⚙️ **[docs/TERRAFORM_TESTING.md](docs/TERRAFORM_TESTING.md)** - Automated test framework documentation

## Project Structure

```
.
├── azure/                       # Azure implementations
│   ├── gitlab-runner/          # GitLab Runner on Azure VMSS
│   ├── github-runner/          # GitHub Runner on Azure VMSS
│   └── azure-devops-agent/     # Azure DevOps Agent on Azure VMSS
├── aws/                        # AWS implementations
│   ├── gitlab-runner/          # GitLab Runner on AWS ASG
│   ├── github-runner/          # GitHub Runner on AWS ASG
│   └── azure-devops-agent/     # Azure DevOps Agent on AWS ASG
├── modules/                    # Shared Terraform modules
│   ├── azure-vmss/            # Azure VMSS module
│   └── aws-asg/               # AWS Auto Scaling Group module
├── examples/                   # 🆕 Preset configurations
│   ├── minimal/               # Testing, learning ($5-20/mo)
│   ├── development/           # Small teams ($40-80/mo)
│   ├── production/            # Business-critical ($150-300/mo)
│   └── high-performance/      # Enterprise ($500-1000/mo)
├── scripts/                    # 🆕 Helper scripts
│   ├── quick-deploy.sh        # Interactive deployment wizard
│   ├── validate-prerequisites.sh  # Prerequisites checker
│   └── run-tests.sh           # Test runner
└── docs/                       # Documentation
    └── TERRAFORM_TESTING.md   # Test framework guide
```

**New to this project?** Check [`examples/`](examples/) for ready-to-use configurations!

## Quick Start

### 🚀 Three Ways to Get Started

#### 1. Interactive Deployment (Easiest - 5 minutes)
Perfect for first-time users:
```bash
./scripts/quick-deploy.sh
```
Guided wizard that does everything for you!

#### 2. Use Preset Configurations (Recommended - 10 minutes)
Choose a proven configuration and deploy:
```bash
# Example: Production GitLab Runner on Azure
cd azure/gitlab-runner
cp ../../examples/production/azure-gitlab.tfvars terraform.tfvars
# Edit 3 required values (project_name, gitlab_url, gitlab_token)
terraform init && terraform apply
```

**Available presets in [`examples/`](examples/):**
- **Minimal** - Testing, learning ($5-20/mo)
- **Development** - Small teams ($40-80/mo)
- **Production** - Business-critical ($150-300/mo)
- **High-Performance** - Enterprise ($500-1000/mo)

See [examples/README.md](examples/README.md) for detailed comparison.

#### 3. Manual Deployment (Advanced - 30 minutes)
Full control over every setting:
```bash
cd azure/gitlab-runner  # or aws/gitlab-runner
cp terraform.tfvars.example terraform.tfvars
# Customize all variables
terraform init && terraform apply
```

**→ See [QUICKSTART.md](QUICKSTART.md) for detailed instructions**

---

### Prerequisites

- Terraform >= 1.5.0
- Azure CLI or AWS CLI (depending on target cloud)
- Runner registration tokens from your CI/CD platform

**Validate your setup:**
```bash
cd azure/gitlab-runner  # or aws/gitlab-runner
bash ../../scripts/validate-prerequisites.sh
```

---

### Azure Deployment

```bash
cd azure/gitlab-runner  # or github-runner, azure-devops-agent

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

### AWS Deployment

```bash
cd aws/gitlab-runner  # or github-runner, azure-devops-agent

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

## Configuration

All implementations support the following key parameters:

- **Instance Type/Size** - Configure VM size with cost/performance guidance (default: Standard_D2s_v3)
- **Min/Max Instances** - Autoscaling limits (default: 0-10 for cost optimization)
- **Spot/Preemptible** - Enable for 60-90% cost savings (default: enabled)
- **OS Image** - Configurable source image (default: Ubuntu 24.04 LTS)
- **Disk Size** - Configurable OS disk (default: 64GB for cost optimization)
- **Disk Type** - Storage performance tier (default: StandardSSD_LRS for balance)
- **Network CIDRs** - Customizable VNet/VPC addressing (default: 10.0.0.0/16)
- **Docker Image** - Runner image (defaults to fok666/*)
- **Instance Count per VM** - Runners per VM, auto-detected by default (0 = vCPU count)
- **Availability Zones** - Multi-zone deployment for high availability (default: zones 1, 2, 3)
- **Custom Scripts** - User data for additional configuration

### Production Features (Optional) ✨ NEW

**Enable these features for production deployments:**

#### 🗄️ Distributed Caching

Significantly faster builds by sharing cached dependencies between ephemeral runners.

```hcl
# Azure Blob Storage
enable_distributed_cache     = true
cache_storage_account_name   = "mycompanyrunnercache"
cache_storage_container_name = "runner-cache"
cache_shared                 = true

# AWS S3
enable_distributed_cache = true
cache_s3_bucket_name     = "my-runner-cache"
cache_shared             = true
```

**Benefits:**
- ⚡ 2-5x faster builds (no re-downloading dependencies)
- 💰 Reduced bandwidth costs
- 🎯 Essential for ephemeral runners

**Cost:** ~$0.02/GB/month (Azure Blob) or ~$0.023/GB/month (S3)

#### 📊 Centralized Logging

Forward runner logs to Azure Log Analytics or CloudWatch for troubleshooting.

```hcl
# Azure Log Analytics
enable_centralized_logging  = true
log_analytics_workspace_id  = "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{ws}"
log_analytics_workspace_key = "your-workspace-key"
log_retention_days          = 30

# AWS CloudWatch
enable_centralized_logging = true
cloudwatch_log_group_name  = "/aws/runners/gitlab"
log_retention_days         = 30
```

**Benefits:**
- 🔍 Troubleshoot ephemeral runners after termination
- 📈 Long-term log retention for compliance
- 🚨 Advanced alerting and anomaly detection

**Cost:** ~$0.50/GB ingested + $0.03/GB/month retention

#### 📈 Runner Monitoring

Expose Prometheus metrics for observability and alerting.

```hcl
enable_runner_monitoring = true
metrics_port             = 9252
```

**Benefits:**
- 📊 Track job duration, queue depth, success rate
- 🎯 Proactive alerting on runner failures
- 📉 Capacity planning insights

**Integration:** Connect to Grafana, Azure Monitor, or CloudWatch

#### ⚡ Webhook-Based Scaling (GitHub Actions)

Scale runners instantly based on workflow job events.

```hcl
enable_webhook_scaling = true
webhook_secret         = "your-secret-key"
```

**Benefits:**
- ⚡ Instant response to job queues (vs 5-10 min with CPU-based scaling)
- 💰 More efficient resource utilization
- 🎯 No waiting for runners to spin up

**Setup:** Configure webhook in GitHub repository/organization settings

### Default Configuration Philosophy

Defaults are optimized for:
- ✅ **Lowest Cost**: Spot instances, 64GB disks, scale-to-zero
- ✅ **Maximum Security**: SSH disabled, encrypted disks, least privilege IAM
- ✅ **Sufficient Performance**: StandardSSD disks, balanced VM sizes
- ⚙️ **Easy Customization**: All settings adjustable with clear tradeoff documentation

**Production Recommendation:** Enable distributed caching, logging, and monitoring for best results.

### Security Configuration

**🔒 All implementations are secure by default:**

- ❌ **SSH Access**: Disabled (can be enabled with specific IP restrictions)
- ✅ **IMDSv2** (AWS): Required for metadata access (protects against SSRF attacks)
- ❌ **Public IPs** (AWS): Not assigned (use NAT Gateway for internet access)
- ✅ **Disk Encryption**: Enabled on all volumes
- ✅ **Least Privilege IAM**: Minimal required permissions only

**To customize security settings**, see [SECURITY.md](SECURITY.md) for detailed documentation including:
- Security implications of each setting
- When and why you might need to change defaults
- Recommended alternatives for secure access
- Compliance and audit considerations

**Important**: Review [SECURITY.md](SECURITY.md) before changing any default security settings.

## Getting Started

### First-Time Users

1. **Read [QUICKSTART.md](QUICKSTART.md)** - Choose your deployment path
2. **Check [examples/](examples/)** - Browse preset configurations
3. **Run the validator** - Ensure prerequisites are met:
   ```bash
   bash scripts/validate-prerequisites.sh
   ```
4. **Deploy!** - Use the interactive wizard or presets

### Experienced Users

1. Copy a preset from [`examples/`](examples/) that matches your needs
2. Customize as required
3. Deploy with Terraform

### Advanced Users

1. Review [ARCHITECTURE.md](ARCHITECTURE.md) for deep dive
2. Customize modules in `modules/`
3. Implement advanced patterns (multi-region, custom autoscaling, etc.)

---

## Support & Contributing

- **📖 Documentation:** See individual README files and docs/
- **🐛 Issues:** [GitHub Issues](https://github.com/fok666/selfhosted-devops/issues)
- **💬 Discussions:** [GitHub Discussions](https://github.com/fok666/selfhosted-devops/discussions)
- **🤝 Contributing:** PRs welcome! See project guidelines in [.github/copilot-instructions.md](.github/copilot-instructions.md)

---

## What's New

**🆕 Recent Additions:**
- ✅ **Examples directory** with preset configurations (Minimal, Development, Production, High-Performance)
- ✅ **Interactive deployment** script for guided setup
- ✅ **Prerequisites validator** to check your environment before deploy
- ✅ **Improved QUICKSTART** with decision wizard and troubleshooting
- ✅ **Platform comparison** matrix to help choose the right runner

---

## Cost Estimator

| Configuration | Azure Monthly | AWS Monthly | Annual Savings with Spot |
|--------------|---------------|-------------|--------------------------|
| **Minimal** (scale-to-zero) | $5-20 | $3-15 | ~$600-800 |
| **Development** (1-3 runners) | $40-80 | $35-70 | ~$2,000-3,000 |
| **Production** (2-10 runners) | $150-300 | $120-250 | ~$8,000-12,000 |
| **High-Performance** (5-20 runners) | $500-1000 | $400-800 | ~$25,000-35,000 |

*Estimates assume spot instances and autoscaling. Actual costs vary by region and usage.*

**💡 Tip:** Start with Minimal configuration, monitor for 2 weeks, then upgrade if needed.

---

## License

This infrastructure is designed for **maximum cost efficiency**:

1. **Spot/Preemptible Instances** - 60-90% discount (enabled by default)
2. **Autoscaling** - Scale to zero when not in use (min_instances = 0)
3. **Right-Sizing** - Optimized defaults with configurable options
4. **64GB Disks** - Cost-optimized default, sufficient for most workloads
5. **StandardSSD Storage** - Balanced cost and performance (~$5/mo for 64GB)
6. **Ephemeral** - No persistent storage costs
7. **Graceful Shutdown** - Monitors termination events to avoid job failures

**Estimated Monthly Cost per VM:**
- Spot VM (Standard_D2s_v3): ~$7-21/month (vs ~$70 on-demand)
- OS Disk (64GB StandardSSD): ~$5/month
- Network: ~$1-5/month
- **Total**: ~$13-31/month with spot vs ~$76/month on-demand

**Performance Options** (when speed matters more than cost):
- Upgrade to Premium_LRS disk: +$5/mo, 2-3x IOPS
- Use Standard_D4s_v3 VM: +$70/mo, 2x vCPUs
- Disable spot instances: +$50/mo, guaranteed availability

## Architecture

### Azure (VMSS)

- Virtual Machine Scale Set with spot instances
- Azure Load Balancer (optional)
- Scheduled Events monitoring via IMDS
- Custom Script Extension for runner setup

### AWS (Auto Scaling Groups)

- Auto Scaling Group with spot instances
- EC2 Instance Metadata Service (IMDSv2)
- User Data for runner setup
- Spot Instance Termination monitoring

## Security Considerations

**🔐 This infrastructure follows security-first principles with secure defaults.**

### Key Security Features

- **Minimal Attack Surface**: SSH disabled, no public IPs by default (AWS)
- **Defense in Depth**: Network isolation, encryption, IAM/RBAC least privilege
- **Secure Metadata Access**: IMDSv2 required on AWS to prevent SSRF attacks
- **Secrets Management**: Sensitive variables marked, recommend external secret stores
- **Audit & Compliance**: Monitoring enabled, compliance with security frameworks

### Production Checklist

Before deploying to production, review:
- [ ] [SECURITY.md](SECURITY.md) - Comprehensive security documentation
- [ ] Verify all security defaults are appropriate for your environment
- [ ] Configure secret management (Key Vault, Secrets Manager, or Vault)
- [ ] Enable monitoring and alerting
- [ ] Review and test disaster recovery procedures

**⚠️ Important**: Review security implications before changing any default settings. See [SECURITY.md](SECURITY.md) for detailed guidance.

### Common Security Patterns

```hcl
# Secure production configuration (AWS)
enable_ssh_access               = false  # Use AWS Systems Manager instead
enable_imdsv2                   = true   # Required for security
associate_public_ip_address     = false  # Use NAT Gateway
```

For detailed security documentation, attack scenarios, and mitigation strategies, see [SECURITY.md](SECURITY.md).

## Configuration Reference

### Common Variables (All Implementations)

#### Required Variables
```hcl
# CI/CD Platform Configuration (varies by implementation)
gitlab_url   = "https://gitlab.com"           # GitLab Runner
github_url   = "https://github.com/org/repo"  # GitHub Runner
azp_url      = "https://dev.azure.com/org"    # Azure DevOps Agent

# Authentication (sensitive)
gitlab_token = "glrt-xxxx"  # GitLab
github_token = "ghp-xxxx"   # GitHub
azp_token    = "pat-xxxx"   # Azure DevOps
```

#### Cost-Optimized Defaults
```hcl
# Instance Configuration
use_spot_instances         = true              # 60-90% savings (DEFAULT)
min_instances              = 0                 # Scale to zero (DEFAULT)
max_instances              = 10                # Safety limit (DEFAULT)
default_instances          = 1                 # Initial capacity (DEFAULT)
runner_count_per_instance  = 0                 # Auto-detect from vCPU (DEFAULT)

# VM/Instance Size
vm_sku                = "Standard_D2s_v3" # Azure: 2 vCPU, 8GB (DEFAULT)
instance_type         = "t3.medium"       # AWS: 2 vCPU, 4GB (DEFAULT)

# Storage (Cost-Optimized)
os_disk_size_gb       = 64                # Sufficient for most (DEFAULT)
os_disk_type          = "StandardSSD_LRS" # Balanced cost/perf (DEFAULT)

# OS Image
source_image_reference = {                # Ubuntu 24.04 LTS (DEFAULT)
  publisher = "Canonical"
  offer     = "ubuntu-24_04-lts"
  sku       = "server"
  version   = "latest"
}

# Network
vnet_address_space    = "10.0.0.0/16"     # Customizable (DEFAULT)
subnet_address_prefix = "10.0.1.0/24"     # Customizable (DEFAULT)

# High Availability
zones                 = ["1", "2", "3"]   # Multi-zone (DEFAULT)

# Security (Secure by Default)
enable_ssh_access              = false    # Disabled (DEFAULT)
nsg_outbound_internet_access   = true     # Required for CI/CD (DEFAULT)
egress_cidr_blocks             = ["0.0.0.0/0"]  # AWS: All egress (DEFAULT)
```

#### Performance-Optimized Configuration
```hcl
# For faster builds (higher cost)
use_spot_instances         = false             # Guaranteed availability
vm_sku                     = "Standard_F4s_v2" # 4 vCPU, compute-optimized
os_disk_size_gb            = 128               # More caching space
os_disk_type               = "Premium_LRS"     # 2-3x faster I/O
min_instances              = 2                 # Always ready
runner_count_per_instance  = 1                 # Dedicated resources

# Cost impact: ~3-4x vs defaults, 30-50% faster builds
```

#### High-Availability Configuration
```hcl
# For production reliability
use_spot_instances    = false             # No interruptions
min_instances         = 3                 # Always available
max_instances         = 50                # Handle peak load
zones                 = ["1", "2", "3"]   # Multi-zone (default)
vm_sku                = "Standard_D4s_v3" # More capacity

# Cost impact: ~5-6x vs defaults, 99.9% availability
```

### Variable Descriptions and Tradeoffs

See implementation-specific `variables.tf` files for comprehensive documentation including:
- Cost implications with approximate monthly costs
- Performance tradeoffs between options
- Security considerations
- Recommended values for different scenarios

## Testing

This project uses **Terraform's native testing framework** for validation without requiring cloud resources.

### Quick Test Commands

```bash
# Test specific module
cd modules/aws-asg
terraform init -backend=false
terraform test

# Test specific configuration
cd azure/gitlab-runner
terraform init -backend=false
terraform test

# Run all tests
./scripts/run-tests.sh
```

### What's Tested

- ✅ **Security Defaults** - SSH disabled, IMDSv2 enabled, encryption on
- ✅ **Variable Validation** - Required variables, constraints, invalid values
- ✅ **Cost Optimization** - Spot instances, scale-to-zero, disk sizing
- ✅ **Autoscaling** - Min/max limits, thresholds, cooldown periods
- ✅ **Network Isolation** - Security groups, private subnets, NSG rules
- ✅ **High Availability** - Multi-AZ, instance distribution, health checks

### Test Coverage

| Component | Unit Tests | Integration Tests | Status |
|-----------|------------|-------------------|--------|
| AWS ASG Module | ✅ | N/A | Covered |
| Azure VMSS Module | ✅ | N/A | Covered |
| AWS GitLab Runner | N/A | ✅ | Covered |
| Azure GitLab Runner | N/A | ✅ | Covered |
| Other Runners | ⚠️ | ⚠️ | Pending |

**CI/CD Integration**: Tests run automatically on every push and pull request via GitHub Actions.

**Documentation**: See [docs/TERRAFORM_TESTING.md](docs/TERRAFORM_TESTING.md) for comprehensive testing guide including:
- Writing new tests
- Testing best practices
- Troubleshooting common issues
- Advanced testing patterns

## Monitoring & Logs

- Cloud-native monitoring (Azure Monitor / CloudWatch)
- Runner logs via Docker
- Termination event logs at `/var/log/*_monitor.log`

## License

MIT License - See individual runner repositories for their licenses.

## References

- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/actions/hosting-your-own-runners)
- [Azure DevOps Self-Hosted Agents](https://learn.microsoft.com/azure/devops/pipelines/agents/agents)
- [Azure Spot VMs](https://learn.microsoft.com/azure/virtual-machines/spot-vms)
- [EC2 Spot Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html)
