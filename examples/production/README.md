# Production Configuration

**Goal:** Business-critical CI/CD pipelines with high availability and reliability.

## 💰 Cost Estimate

- **Azure:** $150-300/month
- **AWS:** $120-250/month
- **Idle cost:** ~$50-70/month (maintains baseline capacity)

## ⚙️ Configuration Highlights

- **Autoscaling:** 2-10 instances (always maintains 2-3 baseline)
- **VM/Instance Type:** 
  - Azure: Standard_D2s_v3 (2 vCPU, 8GB RAM, consistent CPU)
  - AWS: t3.large (2 vCPU, 8GB RAM, burstable)
- **Spot Instances:** 80-90% (balanced with reliability)
- **Disk:** 128GB StandardSSD/gp3 (extensive Docker caching)
- **Runners per VM:** Auto-detected (2 for 2 vCPU instances)
- **Total Capacity:** 4-20 concurrent runners

## ✅ Use Cases

- 🏢 Production CI/CD pipelines
- 👥 Medium to large teams (10-50 developers)
- ⚡ Fast, consistent build times required
- 🔒 Higher availability and reliability needed
- 📊 Multiple concurrent pipelines
- 🚀 Frequent deployments to production

## 🎯 Key Features

### High Availability
- **Minimum 2 instances** always running
- **Multi-zone deployment** for resilience
- **Graceful spot termination** handling
- **Fast scaling** response to demand

### Performance
- **No cold start delays** (always warm)
- **Consistent CPU performance**
- **Extensive disk caching** (128GB)
- **Handles 10-20+ concurrent jobs**

### Reliability
- **Aggressive scale-out** (65% CPU threshold)
- **Conservative scale-in** (25% CPU threshold)
- **Spot + on-demand mix** available
- **Auto-recovery** from failures

## 🚀 Quick Start

### Azure
```bash
cd azure/gitlab-runner
cp ../../examples/production/azure-gitlab.tfvars terraform.tfvars

# Edit terraform.tfvars and set:
# - project_name (your project name)
# - gitlab_url (your GitLab URL)
# - gitlab_token (from GitLab Settings > CI/CD > Runners)

terraform init
terraform plan
terraform apply
```

### AWS
```bash
cd aws/gitlab-runner
cp ../../examples/production/aws-gitlab.tfvars terraform.tfvars

# Edit terraform.tfvars and set:
# - project_name (your project name)
# - gitlab_url (your GitLab URL)
# - gitlab_token (from GitLab Settings > CI/CD > Runners)

terraform init
terraform plan
terraform apply
```

## 📊 Expected Behavior

### Scaling Pattern
```
Normal Load: 2-3 instances (4-6 runners)
Peak Load:   5-10 instances (10-20 runners)
Minimum:     2 instances (always available)
Maximum:     10 instances (cost cap)
```

### Performance
- **Cold start:** None (always warm)
- **Scale-up time:** 1-2 minutes
- **Scale-down time:** 10-15 minutes (conservative)
- **Build time:** Fast and consistent
- **Concurrent jobs:** 10-20+ (depending on job complexity)

## ⚖️ Tradeoffs vs Other Configs

### vs Minimal
- ✅ Much better availability (no cold starts)
- ✅ Higher capacity (10x+ concurrent jobs)
- ✅ Faster, more consistent performance
- ❌ Higher baseline cost (~$50/mo vs $0)

### vs Development
- ✅ Higher availability (min 2 vs 1)
- ✅ More capacity (max 10 vs 5)
- ✅ Better caching (128GB vs 100GB)
- ❌ 2-3x higher cost

### vs High-Performance
- ✅ Much lower cost (~$200 vs $700)
- ❌ Lower capacity (max 10 vs 20 instances)
- ❌ Smaller VMs (2 vCPU vs 4 vCPU)
- ❌ Less disk space (128GB vs 256GB)

## 🔧 Customization Options

### Need More Reliability?
```hcl
# Increase baseline capacity
min_instances     = 3
default_instances = 4

# More aggressive scaling
cpu_scale_out_threshold = 60
```

### Need Higher Capacity?
```hcl
# Allow more instances
max_instances = 15

# Or use larger VMs
vm_sku = "Standard_D4s_v3"  # 4 vCPU, 16GB RAM
```

### Want to Reduce Cost?
```hcl
# Lower baseline (but less available)
min_instances = 1

# Or scale to zero (but cold starts return)
min_instances = 0
```

## 🔍 Monitoring Checklist

After deployment, monitor:

### Daily (First Week)
- [ ] Runner availability in GitLab
- [ ] Job queue lengths
- [ ] Instance count and scaling behavior
- [ ] CPU utilization patterns

### Weekly
- [ ] Cost trends (Azure Cost Management / AWS Cost Explorer)
- [ ] Autoscaling effectiveness
- [ ] Spot instance interruption rate
- [ ] Build time consistency

### Monthly
- [ ] Adjust `max_instances` based on peak demand
- [ ] Review disk usage (consider 256GB if >80% full)
- [ ] Evaluate if larger VMs needed for faster builds
- [ ] Compare actual costs vs estimates

## 🚨 Alerts to Configure

Recommended CloudWatch/Azure Monitor alerts:

1. **High queue length** → Consider increasing max_instances
2. **Consistent high CPU** → Consider larger VM sizes
3. **Frequent spot terminations** → Review spot max price
4. **Cost exceeds budget** → Review autoscaling settings

## 💡 Pro Tips

### Optimize for Your Team
1. **Monitor for 2 weeks** to understand patterns
2. **Adjust thresholds** based on actual usage
3. **Right-size VMs** based on job requirements
4. **Balance cost and performance** for your needs

### Gradual Rollout
1. **Start with this config** for new projects
2. **Migrate critical pipelines** one at a time
3. **Keep old runners** running during transition
4. **Monitor carefully** during first month

### Cost Management
1. **Review monthly costs** in cloud portal
2. **Adjust max_instances** to cap spending
3. **Consider reserved instances** if usage stable
4. **Use tags** for cost allocation

## 📈 Scaling to Enterprise

When you outgrow this configuration:

```bash
# Upgrade to High-Performance
cp ../../examples/high-performance/azure-gitlab.tfvars terraform.tfvars
terraform plan
terraform apply
```

Or customize further:
- Multi-region deployment
- Dedicated VMs for different workloads
- Integration with monitoring/alerting
- Custom autoscaling policies
