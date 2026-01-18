# Development Configuration

**Goal:** Dev/test environments, small-medium teams with balanced cost and performance.

## 💰 Cost Estimate

- **Azure:** $40-80/month
- **AWS:** $35-70/month
- **Idle cost:** ~$20-25/month (maintains 1 baseline instance)

## ⚙️ Configuration Highlights

- **Autoscaling:** 1-5 instances (maintains 1 baseline)
- **VM/Instance Type:** 
  - Azure: Standard_D2s_v3 (2 vCPU, 8GB RAM, consistent CPU)
  - AWS: t3.large (2 vCPU, 8GB RAM, burstable)
- **Spot Instances:** 100% (cost savings)
- **Disk:** 100GB StandardSSD/gp3 (good Docker caching)
- **Runners per VM:** Auto-detected (2 for 2 vCPU instances)
- **Total Capacity:** 2-10 concurrent runners

## ✅ Use Cases

- 👥 Small to medium teams (5-20 developers)
- 🔨 Development and testing pipelines
- 🚀 Feature branch CI/CD
- 💰 Budget-conscious production-like environment
- 📦 Multiple concurrent builds needed
- 🧪 Pre-production validation

## 🎯 Key Features

### Balanced Cost/Performance
- **Baseline instance** always ready (no cold start)
- **Spot instances** for 80-90% cost savings
- **Adequate resources** for most development workloads
- **Scales up** when needed (up to 5 instances)

### Fast Response
- **No cold start delays** (1 instance always running)
- **Quick scale-up** (1-2 minutes to add capacity)
- **Good caching** (100GB disk)
- **Handles bursts** well

### Development-Friendly
- **Sufficient capacity** for team sprints
- **Cost-effective** for continuous use
- **Easy to upgrade** to Production when ready
- **Good for testing** autoscaling behavior

## 🚀 Quick Start

### Azure
```bash
cd azure/gitlab-runner  # or github-runner, azure-devops-agent
cp ../../examples/development/azure-gitlab.tfvars terraform.tfvars

# Edit terraform.tfvars and set:
# - project_name (your project name)
# - gitlab_url/github_url/azdo_url (your platform URL)
# - gitlab_token/github_token/azdo_token (your token)

terraform init
terraform plan
terraform apply
```

### AWS
```bash
cd aws/gitlab-runner  # or github-runner, azure-devops-agent
cp ../../examples/development/aws-gitlab.tfvars terraform.tfvars

# Edit terraform.tfvars and set:
# - project_name (your project name)
# - gitlab_url/github_url/azdo_url (your platform URL)
# - gitlab_token/github_token/azdo_token (your token)

terraform init
terraform plan
terraform apply
```

## 📊 Expected Behavior

### Scaling Pattern
```
Normal Load: 1 instance (2 runners)
Moderate:    2-3 instances (4-6 runners)
Peak Load:   4-5 instances (8-10 runners)
Minimum:     1 instance (always available)
Maximum:     5 instances (cost cap)
```

### Performance
- **Cold start:** None (always has 1 instance)
- **Scale-up time:** 1-2 minutes
- **Scale-down time:** 5-10 minutes
- **Build time:** Good for most projects
- **Concurrent jobs:** 5-10 (depending on job complexity)

## ⚖️ Tradeoffs vs Other Configs

### vs Minimal
- ✅ No cold start (1 instance always ready)
- ✅ Higher capacity (max 5 vs 3 instances)
- ✅ Better caching (100GB vs 64GB)
- ❌ Higher baseline cost (~$20/mo vs $0)

### vs Production
- ✅ Lower cost (~$60 vs $200/mo)
- ❌ Lower availability (min 1 vs 2-3)
- ❌ Less capacity (max 5 vs 10 instances)
- ❌ Smaller disk (100GB vs 128GB)

### vs High-Performance
- ✅ Much lower cost (~$60 vs $700/mo)
- ❌ Smaller VMs (2 vCPU vs 4 vCPU)
- ❌ Less capacity (max 5 vs 20 instances)
- ❌ Less disk space (100GB vs 256GB)

## 🔧 Customization Options

### Need More Capacity?
```hcl
# Increase max instances
max_instances = 10

# Or use slightly larger VMs
vm_sku = "Standard_D4s_v3"     # Azure: 4 vCPU
instance_type = "t3.xlarge"    # AWS: 4 vCPU
```

### Want Lower Cost?
```hcl
# Scale to zero (but adds cold start)
min_instances = 0
min_size = 0

# Or use smaller VMs
vm_sku = "Standard_B2s"        # Azure: 2 vCPU, burstable
instance_type = "t3.medium"    # AWS: 2 vCPU, 4GB RAM
```

### Need Better Performance?
```hcl
# Larger disk for more caching
os_disk_size_gb = 128
root_volume_size = 128

# More aggressive scaling
cpu_scale_out_threshold = 60
target_cpu_utilization = 60
```

## 🔍 Monitoring Checklist

After deployment, check:

### Daily (First Week)
- [ ] Runner availability in your CI/CD platform
- [ ] Job queue lengths during peak hours
- [ ] Instance count and scaling behavior
- [ ] Build times compared to expectations

### Weekly
- [ ] Cost trends (should be $40-80/month range)
- [ ] Autoscaling effectiveness
- [ ] Spot instance interruption rate (should be <5%)
- [ ] Disk usage (check if 100GB is sufficient)

### Monthly
- [ ] Adjust `max_instances` if hitting limit frequently
- [ ] Consider upgrading to Production config if needs grow
- [ ] Review if baseline of 1 instance is sufficient
- [ ] Compare actual costs vs estimates

## 💡 Pro Tips

### Team Size Guidelines
- **5-10 developers:** Perfect fit
- **10-15 developers:** May need to increase `max_instances` to 7-8
- **15-20 developers:** Consider Production configuration
- **20+ developers:** Definitely use Production or High-Performance

### Cost Optimization
1. **Monitor actual usage** for 2 weeks
2. **Scale to zero** during weekends if not needed: `min_instances = 0`
3. **Right-size VMs** based on actual CPU usage
4. **Use tags** for cost allocation across teams

### When to Upgrade
Upgrade to **Production** configuration if:
- Jobs frequently wait in queue (>5 minutes)
- Hitting `max_instances` regularly
- Team grows beyond 20 developers
- Need higher availability guarantees
- Build times become critical

### Common Patterns
```hcl
# For small teams (5-10 devs)
min_instances = 1
max_instances = 5

# For medium teams (10-20 devs)
min_instances = 1
max_instances = 8

# For growing teams
min_instances = 2
max_instances = 10
# (Consider Production config at this point)
```

## 📈 Scaling Path

### From Minimal
```bash
# You're already deployed with minimal config
cd azure/gitlab-runner
cp ../../examples/development/azure-gitlab.tfvars terraform.tfvars
# Keep your existing project_name, URLs, tokens
terraform plan
terraform apply
```

### To Production
```bash
# When ready for production-grade
cd azure/gitlab-runner
cp ../../examples/production/azure-gitlab.tfvars terraform.tfvars
# Keep your existing project_name, URLs, tokens
terraform plan
terraform apply
```

## 🎓 What You'll Learn

This configuration teaches:
- ✓ How to balance cost and availability
- ✓ Impact of baseline instances on responsiveness
- ✓ Autoscaling behavior under real workloads
- ✓ Capacity planning for development teams
- ✓ When to scale up to production-grade infrastructure
