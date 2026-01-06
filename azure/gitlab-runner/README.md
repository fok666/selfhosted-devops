# GitLab Runner on Azure VMSS

Terraform configuration for deploying GitLab self-hosted runners on Azure Virtual Machine Scale Sets with spot instances.

## Features

- ✅ **Spot Instances** - Up to 90% cost savings
- ✅ **Autoscaling** - Scale from 0 to max based on CPU utilization
- ✅ **Ephemeral** - VMs are disposable and self-configuring
- ✅ **Docker-in-Docker** - Full Docker support in privileged mode
- ✅ **Graceful Shutdown** - Monitors VMSS scheduled events
- ✅ **Multi-runner per VM** - Maximizes VM utilization

## Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.5.0
- GitLab runner registration token

## Getting the Registration Token

1. Go to your GitLab project/group/instance
2. Navigate to **Settings** > **CI/CD** > **Runners**
3. Click "New project runner" or "New group runner"
4. Copy the registration token (starts with `glrt-`)

## Quick Start

```bash
# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy
terraform apply
```

## Configuration

Key variables in `terraform.tfvars`:

```hcl
gitlab_url   = "https://gitlab.com"
gitlab_token = "glrt-your-token-here"
runner_tags  = "docker,linux,azure,spot"

vm_sku             = "Standard_D2s_v3"
use_spot_instances = true
min_instances      = 0
max_instances      = 10
```

## VM SKUs Recommendations

| Workload | VM SKU | vCPUs | RAM | Cost/Month (spot)* |
|----------|---------|-------|-----|-------------------|
| Light | Standard_B2s | 2 | 4 GB | ~$8 |
| Medium | Standard_D2s_v3 | 2 | 8 GB | ~$15 |
| Heavy | Standard_D4s_v3 | 4 | 16 GB | ~$30 |
| Intensive | Standard_D8s_v3 | 8 | 32 GB | ~$60 |

*Approximate spot pricing (varies by region and availability)

## Cost Optimization

1. **Enable Spot Instances** - Set `use_spot_instances = true`
2. **Scale to Zero** - Set `min_instances = 0`
3. **Right-size VMs** - Choose appropriate VM SKU
4. **Auto-scaling** - Configured automatically based on CPU

## Monitoring

View logs on the VMs:
```bash
# GitLab runner initialization
sudo tail -f /var/log/gitlab-runner-init.log

# VMSS termination monitoring
sudo tail -f /var/log/vmss_monitor.log

# Docker logs
docker logs -f gitlab-runner-1
```

## SSH Access

Get the SSH private key:
```bash
terraform output -raw ssh_private_key > gitlab-runner-key.pem
chmod 600 gitlab-runner-key.pem
```

Find VM IP and connect:
```bash
# Get VM IP from Azure Portal or CLI
ssh -i gitlab-runner-key.pem azureuser@<VM_IP>
```

## Cleanup

```bash
terraform destroy
```

## Architecture

```
┌─────────────────────────────────────┐
│   Azure Virtual Machine Scale Set   │
│  (Spot Instances, Autoscaling 0-10) │
└──────────────┬──────────────────────┘
               │
    ┌──────────┴──────────┐
    │   Ubuntu 22.04 VM   │
    │   with Docker       │
    └──────────┬──────────┘
               │
    ┌──────────┴──────────┐
    │  GitLab Runners     │
    │  (1-N per VM)       │
    │  - Privileged mode  │
    │  - Docker-in-Docker │
    │  - Auto-registered  │
    └─────────────────────┘
```

## Troubleshooting

### Runners not appearing in GitLab

Check VM logs:
```bash
sudo cat /var/log/gitlab-runner-init.log
docker ps -a | grep gitlab-runner
```

### Spot instances being evicted frequently

Increase max price or use on-demand:
```hcl
spot_max_price = 0.10  # Set specific price
# or
use_spot_instances = false
```

### High costs

Ensure autoscaling is working:
```bash
# Check autoscale rules in Azure Portal
# Or with Azure CLI:
az monitor autoscale show --resource-group <rg-name> --name <vmss-name>-autoscale
```

## References

- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)
- [Azure Spot VMs](https://learn.microsoft.com/azure/virtual-machines/spot-vms)
- [VMSS Scheduled Events](https://learn.microsoft.com/azure/virtual-machines/linux/scheduled-events)
