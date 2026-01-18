# Configuration Examples

This directory contains preset configurations for different use cases. Choose the one that matches your needs and copy it to your deployment directory.

## 📁 Available Examples

### 1. Minimal Configuration (`minimal/`)
**Best for:** Learning, testing, minimum cost
- **Scale to zero** when idle (no baseline cost)
- **Spot instances only** (90% cost savings)
- **Small VM size** (Standard_B2s / t3.medium)
- **64GB disk** (sufficient for most workloads)
- **Estimated cost:** $5-20/month (when running)

**Use when:**
- 🧪 Testing the infrastructure
- 💰 Minimizing costs for light workloads
- 📚 Learning how self-hosted runners work

### 2. Development Configuration (`development/`)
**Best for:** Dev/test environments, small teams
- **1-3 runner capacity** (handles light traffic)
- **Spot instances** (significant savings)
- **Balanced VM size** (Standard_D2s_v3 / t3.large)
- **100GB disk** (room for Docker images)
- **Estimated cost:** $40-80/month

**Use when:**
- 👥 Small development team (1-10 developers)
- 🔨 CI/CD for development branches
- 🧩 Multiple concurrent jobs needed

### 3. Production Configuration (`production/`)
**Best for:** Production workloads, medium-large teams
- **3-10 runner capacity** (handles production traffic)
- **Mix of spot and on-demand** (reliability + cost savings)
- **Standard VM size** (Standard_D2s_v3 / t3.large)
- **128GB disk** (extensive Docker caching)
- **Estimated cost:** $150-300/month

**Use when:**
- 🏢 Production CI/CD pipelines
- 👥 Medium to large teams (10-50 developers)
- ⚡ Fast build times required
- 🔒 Higher reliability needed

### 4. High-Performance Configuration (`high-performance/`)
**Best for:** Compute-intensive workloads, large enterprises
- **5-20 runner capacity** (handles heavy load)
- **Larger VM sizes** (Standard_D4s_v3 / t3.xlarge)
- **Premium SSD disks** (faster I/O)
- **256GB disk** (extensive caching)
- **Estimated cost:** $500-1000/month

**Use when:**
- 🚀 Large codebases with complex builds
- 👥 Large teams (50+ developers)
- 💻 CPU/memory intensive workloads (compilations, tests)
- ⚡ Minimum build time critical

---

## 🚀 How to Use

### Step 1: Choose Your Configuration and Platform

Pick the example that matches your needs and platform:

**Available configurations for each platform:**

| Configuration | GitLab | GitHub | Azure DevOps |
|--------------|--------|--------|--------------|
| **Minimal** | ✅ azure-gitlab.tfvars<br>✅ aws-gitlab.tfvars | ✅ azure-github.tfvars<br>✅ aws-github.tfvars | ✅ azure-azdo.tfvars<br>✅ aws-azdo.tfvars |
| **Development** | ✅ azure-gitlab.tfvars<br>✅ aws-gitlab.tfvars | ✅ azure-github.tfvars<br>✅ aws-github.tfvars | ✅ azure-azdo.tfvars<br>✅ aws-azdo.tfvars |
| **Production** | ✅ azure-gitlab.tfvars<br>✅ aws-gitlab.tfvars | ✅ azure-github.tfvars<br>✅ aws-github.tfvars | ✅ azure-azdo.tfvars<br>✅ aws-azdo.tfvars |
| **High-Performance** | ✅ azure-gitlab.tfvars<br>✅ aws-gitlab.tfvars | ✅ azure-github.tfvars<br>✅ aws-github.tfvars | ✅ azure-azdo.tfvars<br>✅ aws-azdo.tfvars |

### Step 2: Copy to Your Deployment

```bash
# Example: Production GitLab Runner on Azure
cd azure/gitlab-runner
cp ../../examples/production/azure-gitlab.tfvars terraform.tfvars

# Example: Production GitHub Actions on AWS
cd aws/github-runner
cp ../../examples/production/aws-github.tfvars terraform.tfvars

# Example: Minimal Azure DevOps Agent on Azure
cd azure/azure-devops-agent
cp ../../examples/minimal/azure-azdo.tfvars terraform.tfvars
```

### Step 3: Customize Required Values

Edit `terraform.tfvars` and set the **required** values for your platform:

**For GitLab:**
```hcl
project_name = "your-project-name"     # Change this
gitlab_url   = "https://gitlab.com"    # Or your GitLab URL
gitlab_token = "glrt-xxxxx"            # Get from GitLab Settings > CI/CD > Runners
```

**For GitHub:**
```hcl
project_name = "your-project-name"     # Change this
github_url   = "https://github.com"    # Or GitHub Enterprise URL
github_token = "ghp_xxxxx"             # Personal Access Token
github_scope = "your-org/repo"         # Repository or organization
```

**For Azure DevOps:**
```hcl
project_name = "your-project-name"           # Change this
azdo_url     = "https://dev.azure.com/org"   # Your Azure DevOps URL
azdo_token   = "xxxxx"                       # Personal Access Token
azdo_pool    = "Default"                     # Agent pool name
```

**Where to get tokens:**
- **GitLab:** Settings → CI/CD → Runners → "New project runner" (starts with `glrt-`)
- **GitHub:** Settings → Developer settings → Personal Access Tokens (needs `repo` scope)
- **Azure DevOps:** User Settings → Personal Access Tokens (needs `Agent Pools (Read & Manage)` scope)

### Step 4: Deploy

```bash
terraform init
terraform plan    # Review what will be created
terraform apply   # Deploy!
```

---

## 📊 Comparison Matrix

| Feature | Minimal | Development | Production | High-Performance |
|---------|---------|-------------|------------|------------------|
| **Min Runners** | 0 | 1 | 2 | 3 |
| **Max Runners** | 3 | 5 | 10 | 20 |
| **VM Size** | Small | Medium | Medium | Large |
| **Disk Size** | 64GB | 100GB | 128GB | 256GB |
| **Spot Instances** | 100% | 100% | 80% | 50% |
| **Monthly Cost** | $5-20 | $40-80 | $150-300 | $500-1000 |
| **Use Case** | Testing | Dev Teams | Production | Enterprise |

---

## 🎯 Decision Helper

Not sure which to choose? Answer these questions:

1. **How many developers?**
   - 1-5 → Minimal or Development
   - 6-20 → Development or Production
   - 21-50 → Production
   - 50+ → High-Performance

2. **What's your priority?**
   - Lowest cost → Minimal
   - Balanced → Development or Production
   - Fastest builds → High-Performance

3. **How critical are your pipelines?**
   - Learning/Testing → Minimal
   - Can tolerate delays → Development
   - Business-critical → Production
   - Mission-critical → High-Performance

4. **What's your workload?**
   - Light (simple tests) → Minimal or Development
   - Medium (full test suite) → Development or Production
   - Heavy (compilations, integrations) → Production or High-Performance
   - Very heavy (large monorepos) → High-Performance

---

## 💡 Pro Tips

### Start Small, Scale Up
Begin with `minimal/` or `development/`, then migrate to `production/` when you validate the setup.

### Mix and Match
You can combine settings from different examples. The examples are starting points, not rigid templates.

### Monitor and Adjust
After deployment:
1. Check Azure Monitor / CloudWatch for actual CPU usage
2. Review your CI/CD job queue lengths
3. Adjust `max_instances` based on peak demand
4. Fine-tune autoscaling thresholds if needed

### Cost Optimization
- Enable scale-to-zero: `min_instances = 0`
- Use spot instances: `use_spot_instances = true`
- Right-size VMs based on actual usage
- Review disk sizes after 1 month

---

## 📚 Additional Resources

- [QUICKSTART.md](../QUICKSTART.md) - Detailed deployment guide
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Architecture deep dive
- [SECURITY.md](../SECURITY.md) - Security best practices
- [TESTING_GUIDE.md](../TESTING_GUIDE.md) - Testing and validation
