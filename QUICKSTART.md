# Quick Start Guide

## Prerequisites

- Terraform >= 1.5.0
- Cloud CLI authenticated (`az login` or `aws configure`)
- CI/CD platform registration token

Validate: `bash scripts/validate-prerequisites.sh`

## Deployment Options

### 1. Interactive

```bash
./scripts/quick-deploy.sh
```

### 2. Preset Configuration

```bash
cd azure/gitlab-runner  # or aws/gitlab-runner
cp ../../examples/production/azure-gitlab.tfvars terraform.tfvars
# Edit: project_name, gitlab_url, gitlab_token
terraform init && terraform apply
```

Presets: `minimal`, `development`, `production`, `high-performance` in `examples/`

### 3. Manual Configuration

```bash
cd azure/gitlab-runner  # or aws/gitlab-runner
cp terraform.tfvars.example terraform.tfvars
# Customize all variables
terraform init && terraform plan && terraform apply
```

## Configuration Examples

### Minimal (Testing)
```hcl
project_name       = "test-runner"
gitlab_url         = "https://gitlab.com"
gitlab_token       = "glrt-xxxxx"
use_spot_instances = true
min_instances      = 0
max_instances      = 2
```

### Production
```hcl
project_name       = "prod-runner"
gitlab_url         = "https://gitlab.com"
gitlab_token       = "glrt-xxxxx"

# Capacity
min_instances      = 2
max_instances      = 10
default_instances  = 3

# Production features
enable_distributed_cache    = true
enable_centralized_logging  = true
enable_runner_monitoring    = true

# Azure
cache_storage_account_name  = "mycompanycache"
log_analytics_workspace_id  = "/subscriptions/..."

# AWS
# cache_s3_bucket_name      = "my-runner-cache"
# cloudwatch_log_group_name = "/aws/runners/gitlab"
```

See `examples/` for complete configurations.

## Platform-Specific Configuration

### GitLab Runner

**Token Location:** Project → Settings → CI/CD → Runners → "New project runner"

```hcl
project_name = "my-gitlab-runner"
gitlab_url   = "https://gitlab.com"  # or self-hosted URL
gitlab_token = "glrt-xxxxx"          # starts with glrt-
```

### GitHub Actions

**Token Creation:**
1. Repository/Organization → Settings → Actions → Runners → "New runner"
2. Generate PAT: Settings → Developer settings → Personal access tokens
3. Scope required: `repo` (or `admin:org` for organization)

```hcl
project_name = "my-github-runner"
github_url   = "https://github.com/myorg/myrepo"
github_token = "ghp_xxxxx"  # starts with ghp_
```

### Azure DevOps Agent

**Token Creation:**
1. Organization Settings → Agent pools → Create pool
2. User Settings → Personal access tokens → New token
3. Scope: Agent Pools (Read & manage)

```hcl
project_name = "my-azdo-agent"
azp_url      = "https://dev.azure.com/myorg"
azp_token    = "xxxxx"  # Azure DevOps PAT
azp_pool     = "Default"  # or custom pool name
```

## Resource Sizing

### VM/Instance Types

| Size | Azure | AWS | vCPU | RAM | Cost/mo (spot) | Use Case |
|------|-------|-----|------|-----|----------------|----------|
| Small | Standard_D2s_v3 | t3.medium | 2 | 8GB/4GB | $7-15 | Dev, light workloads |
| Medium | Standard_D4s_v3 | t3.xlarge | 4 | 16GB | $30-50 | Standard CI/CD |
| Large | Standard_D8s_v3 | m5.2xlarge | 8 | 32GB | $60-100 | Heavy builds, parallel tests |

### Disk Sizing

- **64GB** (default): Sufficient for 90% of workloads
- **128GB**: Large Docker images, extensive caching
- **256GB+**: Monorepos, heavy artifact storage

## Monitoring & Operations

### Status Checks

**Azure:**
```bash
az vmss list --resource-group <rg> --output table
az monitor autoscale show --resource-group <rg> --name <vmss>-autoscale
```

**AWS:**
```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg>
aws autoscaling describe-policies --auto-scaling-group-name <asg>
```

### Logs

**Azure:**
```bash
# View instance logs
az vmss run-command invoke --resource-group <rg> --name <vmss> \
  --command-id RunShellScript \
  --scripts "cat /var/log/cloud-init-output.log"
```

**AWS:**
```bash
# Session Manager (no SSH needed)
aws ssm start-session --target <instance-id>
sudo tail -f /var/log/user-data.log
sudo docker logs <runner-container>
```

## Troubleshooting

### Runners Not Registering

1. **Check token format:**
   - GitLab: `glrt-*`
   - GitHub: `ghp_*`
   - Azure DevOps: Verify PAT hasn't expired

2. **Verify initialization:**
   ```bash
   # On instance
   sudo cat /var/log/cloud-init-output.log  # Azure
   sudo cat /var/log/user-data.log          # AWS
   ```

3. **Check Docker:**
   ```bash
   sudo systemctl status docker
   sudo docker ps -a | grep runner
   sudo docker logs <runner-container>
   ```

### High Costs

1. Verify spot instances enabled: `use_spot_instances = true`
2. Check min_instances: Should be `0` for dev, `2+` for prod
3. Review autoscaling behavior (instances scale down during idle?)
4. Audit disk sizes: `64GB` sufficient for most workloads

### Spot Instance Interruptions

- **Expected behavior:** Cloud providers terminate spot instances with 2-minute warning
- **Graceful shutdown:** Check `/var/log/spot_monitor.log` or `/var/log/termination_monitor.log`
- **Job retry:** Jobs automatically retry on new instances
- **For critical workloads:** Set `use_spot_instances = false`

### Terraform Errors

**"Error creating resource":**
- Check cloud provider quotas
- Verify IAM/RBAC permissions
- Ensure resource names are unique

**"Error: Invalid value":**
- Review `variables.tf` for validation constraints
- Check variable types match (string, number, bool)
- Run `terraform validate` for detailed error messages

## Cleanup

Remove all resources:

```bash
terraform destroy
```

To keep some resources (e.g., storage accounts with cached data):

```bash
# Remove specific resources from state
terraform state rm azurerm_storage_account.cache

# Then destroy rest
terraform destroy
```

## Next Steps

- **Production setup:** See [PRODUCTION_FEATURES.md](PRODUCTION_FEATURES.md)
- **Security hardening:** See [SECURITY.md](SECURITY.md)
- **Testing:** See [TESTING_GUIDE.md](TESTING_GUIDE.md)
- **Architecture details:** See [ARCHITECTURE.md](ARCHITECTURE.md)

## Support

- **Documentation:** README.md, implementation-specific docs
- **Issues:** [GitHub Issues](https://github.com/fok666/selfhosted-devops/issues)
- **Discussions:** [GitHub Discussions](https://github.com/fok666/selfhosted-devops/discussions)
