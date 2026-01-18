# Self-Hosted DevOps Runner Infrastructure as Code

Production-grade Terraform infrastructure for autoscaling, ephemeral CI/CD runners on Azure and AWS with spot instances, Docker-in-Docker, and cost optimization.

[![CodeQL](https://github.com/fok666/selfhosted-devops/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/fok666/selfhosted-devops/actions/workflows/github-code-scanning/codeql)
[![Terraform Validation](https://github.com/fok666/selfhosted-devops/actions/workflows/terraform-validation.yml/badge.svg)](https://github.com/fok666/selfhosted-devops/actions/workflows/terraform-validation.yml)

## Supported Platforms

| Platform | Status | Azure | AWS |
|----------|--------|-------|-----|
| GitLab Runner | ✅ | ✅ | ✅ |
| GitHub Actions | ✅ | ✅ | ✅ |
| Azure DevOps Agent | ✅ | ✅ | ✅ |

## Features

- **Autoscaling** - VMSS (Azure) / Auto Scaling Groups (AWS)
- **Spot Instances** - 60-90% cost savings (default)
- **Ephemeral Runners** - Self-configuring, on-demand
- **Docker-in-Docker** - Full containerization support
- **Ubuntu 24.04 LTS** - Supported until 2029
- **Distributed Caching** - Azure Blob / S3 integration
- **Centralized Logging** - Log Analytics / CloudWatch
- **Prometheus Metrics** - Runner monitoring
- **Webhook Scaling** - Event-driven for GitHub Actions
- **Enhanced Security** - IMDSv2, encrypted disks, least privilege
- **Multi-Cloud** - Consistent Azure and AWS configuration
- **Multi-Architecture** - AMD64 and ARM64 support

See [ARCHITECTURE.md](ARCHITECTURE.md), [DOCKER_IMAGES.md](DOCKER_IMAGES.md), and [SECURITY.md](SECURITY.md) for details.


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
├── examples/                   # Preset configurations
│   ├── minimal/               # Testing, learning ($5-20/mo)
│   ├── development/           # Small teams ($40-80/mo)
│   ├── production/            # Business-critical ($150-300/mo)
│   └── high-performance/      # Enterprise ($500-1000/mo)
├── scripts/                    # Helper scripts
│   ├── quick-deploy.sh        # Interactive deployment
│   ├── validate-prerequisites.sh  # Prerequisites checker
│   └── run-tests.sh           # Test runner
└── docs/                       # Documentation
    └── TERRAFORM_TESTING.md   # Test framework guide
```

## Quick Start

**Prerequisites:** Terraform >= 1.5.0, Azure/AWS CLI authenticated, CI/CD platform tokens

### Option 1: Interactive Deployment
```bash
./scripts/quick-deploy.sh
```

### Option 2: Use Preset Configuration
```bash
cd azure/gitlab-runner  # or aws/gitlab-runner
cp ../../examples/production/azure-gitlab.tfvars terraform.tfvars
# Edit required values: project_name, gitlab_url, gitlab_token
terraform init && terraform apply
```

Presets available in [`examples/`](examples/): minimal, development, production, high-performance

### Option 3: Manual Configuration
```bash
cd azure/gitlab-runner  # or aws/gitlab-runner
cp terraform.tfvars.example terraform.tfvars
# Customize variables
terraform init && terraform apply
```

See [QUICKSTART.md](QUICKSTART.md) for platform-specific details.

## Configuration

### Core Parameters

```hcl
# Instance sizing (Azure)
vm_sku                     = "Standard_D2s_v3"  # Default: 2 vCPU, 8GB RAM
os_disk_size_gb            = 64                  # Default: 64GB
os_disk_type               = "StandardSSD_LRS"   # Default: balanced performance

# Instance sizing (AWS)
instance_type              = "t3.medium"         # Default: 2 vCPU, 4GB RAM
root_volume_size           = 64                  # Default: 64GB

# Autoscaling
use_spot_instances         = true               # Default: 60-90% cost savings
min_instances              = 0                   # Default: scale to zero
max_instances              = 10                  # Default: safety limit
default_instances          = 1                   # Initial capacity
runner_count_per_instance  = 0                   # Auto-detect from vCPU count

# Network
vnet_address_space         = "10.0.0.0/16"      # Customizable
subnet_address_prefix      = "10.0.1.0/24"      # Customizable

# High availability
zones                      = ["1", "2", "3"]    # Multi-zone by default
```

### Production Features (Optional)

All disabled by default. Enable for production deployments:

```hcl
# Distributed caching (2-5x faster builds)
enable_distributed_cache     = true
cache_storage_account_name   = "mycompanyrunnercache"  # Azure
cache_s3_bucket_name         = "my-runner-cache"       # AWS

# Centralized logging
enable_centralized_logging  = true
log_analytics_workspace_id  = "..."                    # Azure
cloudwatch_log_group_name   = "/aws/runners/gitlab"  # AWS
log_retention_days          = 30

# Monitoring
enable_runner_monitoring = true
metrics_port             = 9252

# Webhook-based scaling (GitHub Actions only)
enable_webhook_scaling = true
webhook_secret         = "your-secret-key"
```

See [PRODUCTION_FEATURES.md](PRODUCTION_FEATURES.md) for detailed configuration.

### Security

Secure by default:
- SSH disabled (enable with `enable_ssh_access = true` + specific CIDRs)
- IMDSv2 required (AWS)
- No public IPs (AWS)
- Disk encryption enabled
- Least privilege IAM/RBAC

See [SECURITY.md](SECURITY.md) for detailed security configuration.

## Cost Estimator

| Configuration | Azure Monthly | AWS Monthly | Annual Savings with Spot |
|--------------|---------------|-------------|--------------------------|
| **Minimal** (scale-to-zero) | $5-20 | $3-15 | ~$600-800 |
| **Development** (1-3 runners) | $40-80 | $35-70 | ~$2,000-3,000 |
| **Production** (2-10 runners) | $150-300 | $120-250 | ~$8,000-12,000 |
| **High-Performance** (5-20 runners) | $500-1000 | $400-800 | ~$25,000-35,000 |

## Testing

Terraform's native testing framework validates configurations without cloud resources.

```bash
# Test module
cd modules/aws-asg
terraform init -backend=false && terraform test

# Test configuration
cd azure/gitlab-runner
terraform init -backend=false && terraform test

# Run all tests
./scripts/run-tests.sh
```

See [docs/TERRAFORM_TESTING.md](docs/TERRAFORM_TESTING.md) and [TESTING_GUIDE.md](TESTING_GUIDE.md) for details.

## References

- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/actions/hosting-your-own-runners)
- [Azure DevOps Self-Hosted Agents](https://learn.microsoft.com/azure/devops/pipelines/agents/agents)
- [Azure Spot VMs](https://learn.microsoft.com/azure/virtual-machines/spot-vms)
- [EC2 Spot Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html)
