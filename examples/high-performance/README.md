# High-Performance Configuration

**Goal:** Maximum performance for large enterprises, compute-intensive workloads, and large codebases.

## 💰 Cost Estimate

- **Azure:** $500-1000/month
- **AWS:** $400-800/month
- **Idle cost:** ~$150-200/month (maintains 3-5 baseline instances)

## ⚙️ Configuration Highlights

- **Autoscaling:** 3-20 instances (maintains 3-5 baseline)
- **VM/Instance Type:** 
  - Azure: Standard_D4s_v3 (4 vCPU, 16GB RAM, consistent CPU)
  - AWS: t3.xlarge (4 vCPU, 16GB RAM, burstable)
- **Spot Instances:** 50-80% (balanced with reliability)
- **Disk:** 256GB Premium SSD/gp3 with high IOPS (extensive caching)
- **Runners per VM:** Auto-detected (4 for 4 vCPU instances)
- **Total Capacity:** 12-80 concurrent runners

## ✅ Use Cases

- 🏢 Large enterprises (50+ developers)
- 💻 Compute-intensive workloads (compilations, heavy tests)
- 📦 Large monorepos with complex builds
- ⚡ Sub-5-minute build time requirements
- 🚀 High-frequency deployments (multiple per hour)
- 🔬 Machine learning/data processing pipelines
- 🎯 Multi-stage parallel testing at scale

## 🎯 Key Features

### Maximum Performance
- **Large VMs** (4 vCPU, 16GB RAM)
- **Premium storage** with high IOPS
- **256GB disk** for extensive caching
- **Very aggressive scaling** (60% CPU threshold)
- **High baseline capacity** (3-5 instances always ready)

### Enterprise-Grade
- **Handles massive load** (up to 80 concurrent runners)
- **Minimal queuing** even at peak
- **Fast build times** with powerful hardware
- **Extensive caching** reduces build times
- **Multi-zone deployment** for resilience

### Production-Optimized
- **No performance bottlenecks**
- **Consistent response times**
- **Scales rapidly** to meet demand
- **High availability** built-in
- **Mission-critical reliability**

## 🚀 Quick Start

### Azure
```bash
cd azure/gitlab-runner  # or github-runner, azure-devops-agent
cp ../../examples/high-performance/azure-gitlab.tfvars terraform.tfvars

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
cp ../../examples/high-performance/aws-gitlab.tfvars terraform.tfvars

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
Light Load:  3-5 instances (12-20 runners)
Normal Load: 5-10 instances (20-40 runners)
Peak Load:   15-20 instances (60-80 runners)
Minimum:     3 instances (always available)
Maximum:     20 instances (cost cap)
```

### Performance
- **Cold start:** None (3+ instances always ready)
- **Scale-up time:** <1 minute (very aggressive)
- **Scale-down time:** 15-20 minutes (very conservative)
- **Build time:** Fastest possible with spot pricing
- **Concurrent jobs:** 30-80+ (depending on job complexity)

## ⚖️ Tradeoffs vs Other Configs

### vs Production
- ✅ 2x faster builds (4 vCPU vs 2 vCPU)
- ✅ 2x more capacity (max 20 vs 10 instances)
- ✅ 2x disk space (256GB vs 128GB)
- ✅ Premium storage (faster I/O)
- ❌ 3-4x higher cost

### vs Development
- ✅ 4x more capacity (max 20 vs 5 instances)
- ✅ 2x more powerful VMs
- ✅ 2.5x more disk space
- ✅ Premium storage
- ❌ 10x higher cost

### vs Minimal
- ✅ Always ready (no cold start ever)
- ✅ 40x more capacity potential
- ✅ 4x more powerful VMs
- ✅ 4x disk space
- ❌ 50x higher baseline cost

## 🔧 Customization Options

### Need Even More Capacity?
```hcl
# Increase max instances
max_instances = 30

# Or use even larger VMs
vm_sku = "Standard_D8s_v3"     # Azure: 8 vCPU, 32GB RAM
instance_type = "t3.2xlarge"   # AWS: 8 vCPU, 32GB RAM

# Or add more runners per VM
runner_count_per_vm = 6        # Override auto-detection
```

### Want to Reduce Cost (Slightly)?
```hcl
# Lower baseline
min_instances = 2
default_instances = 3

# Or reduce max
max_instances = 15

# Note: Consider Production config instead
```

### Need Maximum Speed?
```hcl
# Use compute-optimized instances
vm_sku = "Standard_F8s_v2"     # Azure: 8 vCPU, optimized CPU
instance_type = "c5.2xlarge"   # AWS: 8 vCPU, compute optimized

# Even larger disk
os_disk_size_gb = 512
root_volume_size = 512

# Disable spot for guaranteed performance
use_spot_instances = false
```

## 🔍 Monitoring & Optimization

### Critical Metrics to Track

**Daily Monitoring:**
- [ ] Average job queue time (<30 seconds target)
- [ ] Instance count throughout the day
- [ ] CPU utilization per instance (target: 60-80%)
- [ ] Build times (compare to baseline)
- [ ] Spot termination rate

**Weekly Analysis:**
- [ ] Cost trends and anomalies
- [ ] Peak load patterns
- [ ] Disk usage (ensure <80% full)
- [ ] Cache hit rates
- [ ] Failed job rate

**Monthly Review:**
- [ ] Total cost vs budget
- [ ] ROI analysis (developer time saved vs cost)
- [ ] Capacity planning (adjust max_instances)
- [ ] Performance benchmarking
- [ ] Optimization opportunities

### Cost Optimization Strategies

Even at this scale, you can optimize:

1. **Use Reserved Instances** (if load is consistent)
   - 30-50% additional savings on baseline capacity
   - Keep spot for burst capacity

2. **Schedule Scale-Down** (if predictable)
   ```hcl
   # Lower baseline during off-hours
   # Requires custom autoscaling schedule
   ```

3. **Right-Size Based on Actual Usage**
   - Monitor actual CPU/memory usage
   - Adjust VM sizes accordingly
   - May discover 2 vCPU sufficient for some workloads

4. **Optimize Docker Images**
   - Smaller images = faster pulls
   - Better caching = faster builds
   - Less disk space needed

## 💡 Pro Tips

### Team Size Guidelines
- **50-100 developers:** Perfect fit
- **100-200 developers:** May need to increase to 30-40 max instances
- **200+ developers:** Consider multiple deployments or regions
- **Enterprise scale:** Combine with reserved capacity + spot mix

### When This Config Makes Sense

Use High-Performance when:
- ✅ Build times directly impact productivity
- ✅ Team size exceeds 50 developers
- ✅ Multiple teams sharing infrastructure
- ✅ CI/CD is business-critical
- ✅ Cost of waiting exceeds infrastructure cost
- ✅ Complex monorepo with long build times
- ✅ High-frequency deployments (>50/day)

**Don't use if:**
- ❌ Team <20 developers (use Development/Production)
- ❌ Light workloads (use Minimal/Development)
- ❌ Cost is primary concern (use Production)
- ❌ Build times already <5 minutes (use Production)

### ROI Calculation

Calculate if this config saves money:

```
Developer hourly cost: $50-100/hour
Build time saved per developer: 15-30 min/day
Number of developers: 50-200

Savings per day:
50 devs × 0.25 hours × $75 = $937/day = $20,000+/month

Infrastructure cost: $500-1000/month

Net savings: $19,000-19,500/month
```

**If net savings are positive, this config pays for itself!**

### Architecture Patterns

For very large scale:

1. **Multi-Region Deployment**
   - Deploy in multiple regions
   - Route based on geography
   - Better latency, higher availability

2. **Workload Separation**
   - Separate pools for different workloads
   - CPU-intensive vs I/O-intensive
   - Production vs development jobs

3. **Hybrid Approach**
   - Reserved instances for baseline
   - Spot instances for burst
   - Mix of VM sizes for different needs

## 🚨 Important Considerations

### Cost Management
- **Set billing alerts** at 50%, 80%, 100% of budget
- **Review costs weekly** in cloud portal
- **Tag resources** for cost allocation
- **Use `max_instances`** as hard cap
- **Monitor spot pricing** in your region

### Performance Expectations
- **Build times:** 30-50% faster than Production config
- **Queue times:** Should be near-zero
- **Responsiveness:** Instant for most workloads
- **Reliability:** Very high with multi-zone deployment

### Team Communication
- **Document costs** and share with team
- **Show ROI** to stakeholders
- **Get buy-in** before deployment
- **Set expectations** on cost vs performance
- **Regular reviews** of actual vs expected

## 📈 Scaling Path

### From Production
```bash
# When Production can't keep up
cd azure/gitlab-runner
cp ../../examples/high-performance/azure-gitlab.tfvars terraform.tfvars
# Keep your existing project_name, URLs, tokens
terraform plan
terraform apply
```

### Further Scaling
When even this isn't enough:
- Increase `max_instances` to 30-40
- Use larger VMs (8 vCPU, 32GB RAM)
- Deploy in multiple regions
- Implement workload-specific pools
- Consider dedicated hardware or Kubernetes-based runners

## 🎓 Enterprise Best Practices

1. **Capacity Planning:** Review quarterly
2. **Cost Allocation:** Tag by team/project
3. **Performance SLAs:** Define and monitor
4. **Disaster Recovery:** Multi-region ready
5. **Security:** Regular audits and updates
6. **Compliance:** Document and maintain
7. **Optimization:** Continuous improvement

This configuration represents **best-in-class** self-hosted CI/CD infrastructure at spot instance pricing! 🚀
