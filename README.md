# Self-Hosted DevOps Runner Infrastructure as Code

Terraform infrastructure for deploying autoscaling, ephemeral, cost-optimized CI/CD runners on Azure and AWS.

[![CodeQL](https://github.com/fok666/selfhosted-devops/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/fok666/selfhosted-devops/actions/workflows/github-code-scanning/codeql) [![Dependabot Updates](https://github.com/fok666/selfhosted-devops/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/fok666/selfhosted-devops/actions/workflows/dependabot/dependabot-updates) [![Terraform Validation](https://github.com/fok666/selfhosted-devops/actions/workflows/terraform-validation.yml/badge.svg)](https://github.com/fok666/selfhosted-devops/actions/workflows/terraform-validation.yml)

## Supported Runners

- **GitLab Runner** - [fok666/gitlab-selfhosted-runner](https://github.com/fok666/gitlab-selfhosted-runner)
- **GitHub Actions Runner** - [fok666/github-selfhosted-runner](https://github.com/fok666/github-selfhosted-runner)
- **Azure DevOps Agent** - [fok666/azure-devops-agent](https://github.com/fok666/azure-devops-agent)

## Features

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
└── examples/                   # Usage examples and configurations
```

## Quick Start

### Prerequisites

- Terraform >= 1.5.0
- Azure CLI or AWS CLI (depending on target cloud)
- Runner registration tokens from your CI/CD platform

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

### Default Configuration Philosophy

Defaults are optimized for:
- ✅ **Lowest Cost**: Spot instances, 64GB disks, scale-to-zero
- ✅ **Maximum Security**: SSH disabled, encrypted disks, least privilege IAM
- ✅ **Sufficient Performance**: StandardSSD disks, balanced VM sizes
- ⚙️ **Easy Customization**: All settings adjustable with clear tradeoff documentation

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

## Cost Optimization

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
use_spot_instances    = true              # 60-90% savings (DEFAULT)
min_instances         = 0                 # Scale to zero (DEFAULT)
max_instances         = 10                # Safety limit (DEFAULT)
default_instances     = 1                 # Initial capacity (DEFAULT)
instance_count_per_vm = 0                 # Auto-detect from vCPU (DEFAULT)

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
use_spot_instances    = false             # Guaranteed availability
vm_sku                = "Standard_F4s_v2" # 4 vCPU, compute-optimized
os_disk_size_gb       = 128               # More caching space
os_disk_type          = "Premium_LRS"     # 2-3x faster I/O
min_instances         = 2                 # Always ready
instance_count_per_vm = 1                 # Dedicated resources

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

✅ **Security Defaults** - SSH disabled, IMDSv2 enabled, encryption on
✅ **Variable Validation** - Required variables, constraints, invalid values
✅ **Cost Optimization** - Spot instances, scale-to-zero, disk sizing
✅ **Autoscaling** - Min/max limits, thresholds, cooldown periods
✅ **Network Isolation** - Security groups, private subnets, NSG rules
✅ **High Availability** - Multi-AZ, instance distribution, health checks

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
