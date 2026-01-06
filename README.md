# Self-Hosted DevOps Runner Infrastructure as Code

Terraform infrastructure for deploying autoscaling, ephemeral, cost-optimized CI/CD runners on Azure and AWS.

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

- Runners execute in privileged mode (required for DinD)
- Network security groups/security groups configured
- Secrets stored in Key Vault/Secrets Manager (recommended)
- IAM roles with least privilege

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
