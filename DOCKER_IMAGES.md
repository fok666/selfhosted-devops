# Docker Images for Self-Hosted CI/CD Runners

This project showcases custom-built, production-ready Docker images for CI/CD runners with multi-architecture support and variant capabilities.

## Available Images

All images are available on Docker Hub with multi-architecture support (x86-64 and ARM64):

### GitHub Actions Runner
**Repository:** `fok666/github-runner`

| Tag | Architecture | Capabilities | Use Case | Size |
|-----|-------------|--------------|----------|------|
| `latest` (alias for `full`) | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + PowerShell + Azure/AWS PowerShell modules + kubectl + kubelogin + kustomize + helm + jq + yq + Terraform + OpenTofu + Terraspace | Production deployments with comprehensive IaC and cloud tooling | ~2.8GB |
| `full` | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + PowerShell + Azure/AWS PowerShell modules + kubectl + kubelogin + kustomize + helm + jq + yq + Terraform + OpenTofu + Terraspace | Complete toolchain for enterprise workloads | ~2.8GB |
| `minimal` | x86-64, ARM64 | Base Ubuntu 24.04 + Git + sudo only | Cost-optimized, lightweight builds, compiled languages (Go, Rust) | ~400MB |
| `k8s` | x86-64, ARM64 | Docker + kubectl + kubelogin + kustomize + helm + jq + yq | Kubernetes deployments and GitOps workflows | ~1.5GB |
| `iac` | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + jq + yq + Terraform + OpenTofu + Terraspace | Infrastructure as Code (without PowerShell) | ~2.0GB |
| `iac-pwsh` | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + PowerShell + Azure/AWS PowerShell modules + jq + yq + Terraform + OpenTofu + Terraspace | Infrastructure as Code with PowerShell automation | ~2.3GB |

### GitLab Runner
**Repository:** `fok666/gitlab-runner`

| Tag | Architecture | Capabilities | Use Case | Size |
|-----|-------------|--------------|----------|------|
| `latest` (alias for `full`) | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + PowerShell + Azure/AWS PowerShell modules + kubectl + kubelogin + kustomize + helm + jq + yq + Terraform + OpenTofu + Terraspace | Production deployments with comprehensive IaC and cloud tooling | ~2.8GB |
| `full` | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + PowerShell + Azure/AWS PowerShell modules + kubectl + kubelogin + kustomize + helm + jq + yq + Terraform + OpenTofu + Terraspace | Complete toolchain for enterprise workloads | ~2.8GB |
| `minimal` | x86-64, ARM64 | Base Ubuntu 24.04 + Git + sudo only | Cost-optimized, lightweight builds, compiled languages (Go, Rust) | ~400MB |
| `k8s` | x86-64, ARM64 | Docker + kubectl + kubelogin + kustomize + helm + jq + yq | Kubernetes deployments and GitOps workflows | ~1.5GB |
| `iac` | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + jq + yq + Terraform + OpenTofu + Terraspace | Infrastructure as Code (without PowerShell) | ~2.0GB |
| `iac-pwsh` | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + PowerShell + Azure/AWS PowerShell modules + jq + yq + Terraform + OpenTofu + Terraspace | Infrastructure as Code with PowerShell automation | ~2.3GB |

### Azure DevOps Agent
**Repository:** `fok666/azure-devops-agent`

| Tag | Architecture | Capabilities | Use Case | Size |
|-----|-------------|--------------|----------|------|
| `latest` (alias for `full`) | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + PowerShell + Azure/AWS PowerShell modules + kubectl + kubelogin + kustomize + helm + jq + yq + Terraform + OpenTofu + Terraspace | Production deployments with comprehensive IaC and cloud tooling | ~2.8GB |
| `full` | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + PowerShell + Azure/AWS PowerShell modules + kubectl + kubelogin + kustomize + helm + jq + yq + Terraform + OpenTofu + Terraspace | Complete toolchain for enterprise workloads | ~2.8GB |
| `minimal` | x86-64, ARM64 | Base Ubuntu 24.04 + Git + sudo only | Cost-optimized, lightweight builds, compiled languages (Go, Rust) | ~400MB |
| `k8s` | x86-64, ARM64 | Docker + kubectl + kubelogin + kustomize + helm + jq + yq | Kubernetes deployments and GitOps workflows | ~1.5GB |
| `iac` | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + jq + yq + Terraform + OpenTofu + Terraspace | Infrastructure as Code (without PowerShell) | ~2.0GB |
| `iac-pwsh` | x86-64, ARM64 | Docker + Azure CLI + AWS CLI + PowerShell + Azure/AWS PowerShell modules + jq + yq + Terraform + OpenTofu + Terraspace | Infrastructure as Code with PowerShell automation | ~2.3GB |

## Multi-Architecture Support

All images are built as multi-platform manifests supporting:
- **x86-64 (AMD64)**: Standard Intel/AMD processors
- **ARM64 (aarch64)**: AWS Graviton2/3, Azure Ampere Altra, Apple Silicon

Docker automatically pulls the correct architecture for your platform.

## Image Selection Guide

### By Use Case

**🎯 Production - Full Toolchain**
```hcl
docker_image = "fok666/github-runner:full"
# or
docker_image = "fok666/github-runner:latest"  # Alias for 'full'
```
Best for teams with diverse technology stacks. Includes comprehensive IaC, cloud, and Kubernetes tooling.

**💰 Cost-Optimized - Minimal**
```hcl
docker_image = "fok666/github-runner:minimal"
```
Smallest image size, fastest startup. Perfect for simple builds, static sites, or compiled languages (Go, Rust, C++) that don't need runtime dependencies.

**☸️ Kubernetes - K8s Deployments**
```hcl
docker_image = "fok666/github-runner:k8s"
```
Optimized for Kubernetes deployments, GitOps workflows with kubectl, helm, kustomize, and kubelogin.

**🏗️ Infrastructure as Code**
```hcl
# Without PowerShell
docker_image = "fok666/github-runner:iac"

# With PowerShell for Azure/AWS automation
docker_image = "fok666/github-runner:iac-pwsh"
```
Terraform, OpenTofu, Terraspace with cloud CLIs. Choose `iac-pwsh` for Azure PowerShell or AWS Tools for PowerShell.

### By Team Size

| Team Size | Recommended Image | Reasoning |
|-----------|------------------|-----------|  
| 1-5 developers | `minimal` or `k8s`/`iac` | Lower costs, faster iteration, focused tooling |
| 5-20 developers | `full` or `iac-pwsh` | Flexibility for diverse projects |
| 20+ developers | `full` + specialized variants | Standardization with `full` baseline, `k8s`/`iac` for specialized teams |

### By Architecture

**AWS Graviton** (cost savings up to 40%)
```hcl
instance_type = "t4g.medium"  # ARM64
docker_image  = "fok666/github-runner:latest"  # Automatically pulls ARM64
```

**Azure Ampere Altra** (cost savings up to 50%)
```hcl
vm_sku       = "Dpsv5"  # ARM64
docker_image = "fok666/github-runner:latest"  # Automatically pulls ARM64
```

## Cost Impact Analysis

### Image Size vs. Startup Time vs. Monthly Cost

| Image | Size | Startup Time | Data Transfer Cost | Storage Cost (100GB) |
|-------|------|-------------|-------------------|---------------------|
| `minimal` | 400MB | ~8s | $0.01/month | $0.80/month |
| `k8s` | 1.5GB | ~25s | $0.06/month | $3.00/month |
| `iac` | 2.0GB | ~35s | $0.08/month | $4.00/month |
| `iac-pwsh` | 2.3GB | ~40s | $0.09/month | $4.60/month |
| `full` / `latest` | 2.8GB | ~45s | $0.11/month | $5.60/month |

**Recommendation:** Use `minimal` for high-frequency, short-duration jobs. Use `k8s` or `iac` for specialized workflows. Use `full` for maximum flexibility.

## Configuration Examples

### Terraform Configuration

```hcl
# Azure GitHub Runner with minimal image
module "github_runner" {
  source = "./azure/github-runner"
  
  docker_image = "fok666/github-runner:minimal"
  vm_sku       = "Standard_D2s_v3"  # x86-64
  
  # ... other configuration
}

# AWS GitLab Runner with ARM64 k8s image
module "gitlab_runner" {
  source = "./aws/gitlab-runner"
  
  docker_image  = "fok666/gitlab-runner:k8s"
  instance_type = "t4g.medium"  # ARM64 Graviton
  
  # ... other configuration
}

# Azure DevOps Agent with IaC + PowerShell
module "azdo_agent" {
  source = "./azure/azure-devops-agent"
  
  docker_image = "fok666/azure-devops-agent:iac-pwsh"
  vm_sku       = "Standard_D2ps_v5"  # ARM64 Ampere Altra
  
  # ... other configuration
}
```

### Environment-Specific Recommendations

**Development**
```hcl
docker_image       = "fok666/github-runner:minimal"
use_spot_instances = true
min_instances      = 0  # Scale to zero
```

**Staging**
```hcl
docker_image       = "fok666/github-runner:iac"  # Match production tooling
use_spot_instances = true
min_instances      = 1
```

**Production**
```hcl
docker_image       = "fok666/github-runner:full"
use_spot_instances = false  # Reliability over cost
min_instances      = 2       # High availability
```

## Image Update Strategy

### Semantic Versioning

Images follow semantic versioning:
```
fok666/github-runner:1.2.3
                      │ │ │
                      │ │ └─ Patch: Bug fixes, security updates
                      │ └─── Minor: New tools, non-breaking changes
                      └───── Major: Breaking changes, major tool updates
```

### Update Recommendations

**Latest Tag** (Recommended for Development)
```hcl
docker_image = "fok666/github-runner:latest"  # Always points to 'full'
```
- ✅ Always up-to-date with latest features
- ✅ Automatic security patches
- ⚠️ May introduce unexpected changes

**Profile Tag** (Recommended for Production)
```hcl
docker_image = "fok666/github-runner:full"  # Explicit profile
# or
docker_image = "fok666/github-runner:iac-pwsh"  # Specialized profile
```
- ✅ Clear capability expectations
- ✅ Automatic security patches within profile
- ✅ Good balance for most teams

**Pinned Version** (Highest Control)
```hcl
docker_image = "fok666/github-runner:2.321.0-full"  # Pinned version + profile
```
- ✅ Reproducible builds
- ✅ Controlled updates
- ⚠️ Requires manual updates for security patches

## Customization

### Building Custom Variants

If your team needs specific tools not included in the standard profiles:

```dockerfile
# Dockerfile
FROM fok666/github-runner:minimal

# Add your custom tools
RUN apt-get update && apt-get install -y \\
    your-tool \\
    another-tool

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
```

### Extending Existing Profiles

Build on top of specialized profiles:

```dockerfile
# Add Node.js to IaC profile
FROM fok666/github-runner:iac

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \\
    apt-get install -y nodejs && \\
    apt-get clean && rm -rf /var/lib/apt/lists/*
```

### Multi-Stage Builds

For maximum size optimization:

```dockerfile
# Build stage
FROM fok666/github-runner:minimal AS builder
WORKDIR /app
COPY . .
RUN make build

# Runtime stage
FROM fok666/github-runner:minimal
COPY --from=builder /app/dist /usr/local/bin/
```

## Security Considerations

### Image Verification

All images are:
- ✅ Scanned for CVEs with Trivy (fail on CRITICAL)
- ✅ Built with SBOM (Software Bill of Materials) in SPDX format
- ✅ Published to GitHub Container Registry with provenance
- ✅ Built from minimal base images (Ubuntu 24.04 LTS)
- ✅ Regularly updated with security patches
- ✅ Multi-architecture builds verified independently

### Verification

```bash
# Pull specific profile
docker pull fok666/github-runner:iac-pwsh

# Scan for vulnerabilities
trivy image fok666/github-runner:iac-pwsh

# Inspect image layers
docker history fok666/github-runner:iac-pwsh

# Check installed tools
docker run --rm fok666/github-runner:iac-pwsh bash -c "terraform version && az version"
```

## Troubleshooting

### Wrong Architecture Pulled

If Docker pulls the wrong architecture:

```bash
# Explicitly specify platform
docker pull --platform linux/amd64 fok666/github-runner:full
docker pull --platform linux/arm64 fok666/github-runner:full
```

### Image Too Large

If disk space is constrained:

1. Use `minimal` profile (~400MB vs ~2.8GB)
2. Use specialized profiles (`k8s`, `iac`) instead of `full`
3. Enable image pruning in cloud-init/user-data:
```bash
# Add to runcmd
- docker system prune -af --volumes
```

### Missing Tools

If a required tool is missing:

1. **Check available profiles**: 
   - `minimal`: Bare minimum
   - `k8s`: Kubernetes tools
   - `iac`: Terraform/OpenTofu + cloud CLIs
   - `iac-pwsh`: Same as `iac` + PowerShell
   - `full`: Everything

2. **Switch to appropriate profile**:
```hcl
# Wrong: Using minimal for IaC
docker_image = "fok666/github-runner:minimal"  # Missing terraform!

# Right: Use IaC profile
docker_image = "fok666/github-runner:iac"  # Has terraform, opentofu, terraspace
```

3. **Build custom image** (see Customization section)

4. **Install at runtime** (slower, not recommended):
```yaml
# cloud-init.yaml
runcmd:
  - apt-get update && apt-get install -y your-tool
```

### Profile vs Tag Confusion

```bash
# These are PROFILES (what you should use)
fok666/github-runner:full
fok666/github-runner:minimal
fok666/github-runner:k8s
fok666/github-runner:iac
fok666/github-runner:iac-pwsh

# These are VERSION + PROFILE tags (for reproducibility)
fok666/github-runner:2.321.0-full
fok666/github-runner:2.321.0-iac-pwsh

# This is an ALIAS
fok666/github-runner:latest  # Points to 'full'
```

## Support

For issues or feature requests:
- 📧 GitHub Issues: https://github.com/fok666/selfhosted-devops/issues
- 🐳 Docker Hub: https://hub.docker.com/u/fok666
- 📚 Documentation: This file

## Related Documentation

- [QUICKSTART.md](QUICKSTART.md) - Getting started guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture overview
- [SECURITY.md](SECURITY.md) - Security best practices
- Configuration examples can be found in the `terraform.tfvars.example` file within each platform's directory (e.g., `aws/github-runner/`, `azure/gitlab-runner/`)
