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
✅ **Configurable Sizing** - Flexible VM/instance types  
✅ **Graceful Shutdown** - Monitors termination events and stops runners cleanly  
✅ **Multi-Cloud** - Identical configurations for Azure and AWS

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

- **Instance Type/Size** - Configure VM size based on workload
- **Min/Max Instances** - Autoscaling limits
- **Spot/Preemptible** - Enable for cost savings
- **Docker Image** - Runner image (defaults to fok666/*)
- **Runner Count per VM** - Number of runners per VM (default: CPU count)
- **Custom Scripts** - User data for additional configuration

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

1. **Spot/Preemptible Instances** - 70-90% discount
2. **Autoscaling** - Scale to zero when not in use
3. **Right-Sizing** - Configurable instance types
4. **Ephemeral** - No persistent storage costs
5. **Graceful Shutdown** - Monitors termination events to avoid job failures

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
