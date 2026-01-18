# Minimal Configuration

**Goal:** Absolute minimum cost for learning, testing, or light workloads.

## 💰 Cost Estimate

- **Azure:** $5-20/month (only when running)
- **AWS:** $3-15/month (only when running)
- **Idle cost:** $0 (scales to zero)

## ⚙️ Configuration Highlights

- **Autoscaling:** 0-3 instances (scale to zero when idle)
- **VM/Instance Type:** 
  - Azure: Standard_B2s (2 vCPU, 4GB RAM, burstable)
  - AWS: t3.medium (2 vCPU, 4GB RAM, burstable)
- **Spot Instances:** 100% (maximum cost savings)
- **Disk:** 64GB StandardSSD/gp3
- **Runners per VM:** Auto-detected (2 for 2 vCPU instances)

## ✅ Use Cases

- 🧪 Testing the infrastructure
- 📚 Learning how self-hosted runners work
- 👤 Individual developers or very small teams
- 💰 Absolute minimum cost is priority
- 🔬 Development/experimental projects

## ⚠️ Limitations

- **Burstable CPU:** Performance can vary under sustained load
- **Spot only:** Rare possibility of instance termination (auto-recovers)
- **Limited capacity:** Max 3 instances may cause job queuing at peak times
- **Scale-to-zero:** 2-3 minute cold start when first job arrives

## 🚀 Quick Start

### Azure
```bash
cd azure/gitlab-runner
cp ../../examples/minimal/azure-gitlab.tfvars terraform.tfvars

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
cp ../../examples/minimal/aws-gitlab.tfvars terraform.tfvars

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
Jobs Queued: 0  → Instances: 0 (idle, no cost)
Jobs Queued: 1  → Instances: 1 (scales up in ~2-3 minutes)
Jobs Queued: 3+ → Instances: 2-3 (scales to match demand)
Jobs Queued: 0  → Instances: 0 (scales down after 10 minutes idle)
```

### Performance
- **Cold start:** 2-3 minutes (when scaling from zero)
- **Warm scaling:** 1-2 minutes (when adding instances)
- **Build time:** Good for small-medium projects
- **Concurrent jobs:** 2-6 jobs (depending on job complexity)

## 🎓 What You'll Learn

This configuration is perfect for understanding:
- ✓ How autoscaling works (including scale-to-zero)
- ✓ Spot instance behavior and savings
- ✓ Runner registration and lifecycle
- ✓ Cost optimization strategies
- ✓ Basic Terraform operations

## 📈 Scaling Up

When you're ready for more capacity:

1. **Quick fix:** Increase `max_instances` to 5-10
2. **Better performance:** Upgrade to Development configuration
3. **Production:** Migrate to Production configuration

```bash
# Easy upgrade path
cp ../../examples/development/azure-gitlab.tfvars terraform.tfvars
terraform plan
terraform apply
```

## 🔍 Monitoring

After deployment, check:
- **Runner status:** GitLab → Settings → CI/CD → Runners
- **Instance count:** Azure Portal / AWS Console
- **Costs:** Azure Cost Management / AWS Cost Explorer

## 💡 Pro Tips

1. **Test with this config first** before moving to production
2. **Monitor actual usage** for 1-2 weeks
3. **Adjust max_instances** based on peak job queue
4. **Consider Development config** if you have >2 concurrent jobs regularly
5. **Keep scale-to-zero** (`min_instances = 0`) to minimize costs
