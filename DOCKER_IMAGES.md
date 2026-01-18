# Docker Images for Self-Hosted CI/CD Runners

This project showcases custom-built, production-ready Docker images for CI/CD runners with multi-architecture support and variant capabilities.

## Available Images

All images are available on Docker Hub with multi-architecture support (x86-64 and ARM64):

### GitHub Actions Runner
**Repository:** `fok666/github-runner`

| Tag | Architecture | Capabilities | Use Case | Size |
|-----|-------------|--------------|----------|------|
| `latest` | x86-64, ARM64 | Full toolchain (Docker, Node.js, Python, Go, Rust, AWS CLI, Azure CLI, kubectl) | Production deployments with comprehensive tooling | ~2.5GB |
| `minimal` | x86-64, ARM64 | Docker + Git only | Cost-optimized, lightweight builds | ~500MB |
| `node` | x86-64, ARM64 | Docker + Node.js + npm/yarn | JavaScript/TypeScript projects | ~1.2GB |
| `python` | x86-64, ARM64 | Docker + Python 3.11 + pip/poetry | Python projects | ~1.1GB |
| `golang` | x86-64, ARM64 | Docker + Go 1.21 | Go projects | ~1.3GB |
| `cloud` | x86-64, ARM64 | Docker + AWS CLI + Azure CLI + kubectl | Cloud-native deployments | ~1.8GB |

### GitLab Runner
**Repository:** `fok666/gitlab-runner`

| Tag | Architecture | Capabilities | Use Case | Size |
|-----|-------------|--------------|----------|------|
| `latest` | x86-64, ARM64 | Full toolchain (Docker, Node.js, Python, Go, Rust, AWS CLI, Azure CLI, kubectl) | Production deployments with comprehensive tooling | ~2.5GB |
| `minimal` | x86-64, ARM64 | Docker + Git only | Cost-optimized, lightweight builds | ~500MB |
| `node` | x86-64, ARM64 | Docker + Node.js + npm/yarn | JavaScript/TypeScript projects | ~1.2GB |
| `python` | x86-64, ARM64 | Docker + Python 3.11 + pip/poetry | Python projects | ~1.1GB |
| `golang` | x86-64, ARM64 | Docker + Go 1.21 | Go projects | ~1.3GB |
| `cloud` | x86-64, ARM64 | Docker + AWS CLI + Azure CLI + kubectl | Cloud-native deployments | ~1.8GB |

### Azure DevOps Agent
**Repository:** `fok666/azure-devops-agent`

| Tag | Architecture | Capabilities | Use Case | Size |
|-----|-------------|--------------|----------|------|
| `latest` | x86-64, ARM64 | Full toolchain (Docker, Node.js, Python, .NET, Go, Rust, AWS CLI, Azure CLI, kubectl) | Production deployments with comprehensive tooling | ~2.8GB |
| `minimal` | x86-64, ARM64 | Docker + Git only | Cost-optimized, lightweight builds | ~500MB |
| `dotnet` | x86-64, ARM64 | Docker + .NET 8.0 SDK | .NET projects | ~1.5GB |
| `node` | x86-64, ARM64 | Docker + Node.js + npm/yarn | JavaScript/TypeScript projects | ~1.2GB |
| `python` | x86-64, ARM64 | Docker + Python 3.11 + pip/poetry | Python projects | ~1.1GB |
| `golang` | x86-64, ARM64 | Docker + Go 1.21 | Go projects | ~1.3GB |
| `cloud` | x86-64, ARM64 | Docker + AWS CLI + Azure CLI + kubectl | Cloud-native deployments | ~1.8GB |

## Multi-Architecture Support

All images are built as multi-platform manifests supporting:
- **x86-64 (AMD64)**: Standard Intel/AMD processors
- **ARM64 (aarch64)**: AWS Graviton2/3, Azure Ampere Altra, Apple Silicon

Docker automatically pulls the correct architecture for your platform.

## Image Selection Guide

### By Use Case

**🎯 Production - Full Toolchain**
```hcl
docker_image = "fok666/github-runner:latest"
```
Best for teams with diverse technology stacks. Includes everything needed for most CI/CD workflows.

**💰 Cost-Optimized - Minimal**
```hcl
docker_image = "fok666/github-runner:minimal"
```
Smallest image size, fastest startup. Perfect for simple builds, static sites, or Go/Rust projects that compile to single binaries.

**🌐 Cloud-Native - Cloud Tools**
```hcl
docker_image = "fok666/github-runner:cloud"
```
Optimized for Kubernetes deployments, infrastructure as code, and cloud automation.

**🔧 Language-Specific**
```hcl
# Node.js/TypeScript
docker_image = "fok666/github-runner:node"

# Python
docker_image = "fok666/github-runner:python"

# Go
docker_image = "fok666/github-runner:golang"

# .NET (Azure DevOps only)
docker_image = "fok666/azure-devops-agent:dotnet"
```

### By Team Size

| Team Size | Recommended Image | Reasoning |
|-----------|------------------|-----------|
| 1-5 developers | `minimal` or language-specific | Lower costs, faster iteration |
| 5-20 developers | `latest` | Flexibility for diverse projects |
| 20+ developers | `latest` + custom variants | Standardization with specialization |

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
| `minimal` | 500MB | ~10s | $0.02/month | $1.00/month |
| `node`/`python`/`golang` | ~1.2GB | ~20s | $0.05/month | $2.40/month |
| `cloud` | 1.8GB | ~30s | $0.07/month | $3.60/month |
| `latest` | 2.5GB | ~45s | $0.10/month | $5.00/month |

**Recommendation:** Use `minimal` for high-frequency, short-duration jobs. Use `latest` for complex, infrequent builds.

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

# AWS GitLab Runner with ARM64 cloud image
module "gitlab_runner" {
  source = "./aws/gitlab-runner"
  
  docker_image  = "fok666/gitlab-runner:cloud"
  instance_type = "t4g.medium"  # ARM64 Graviton
  
  # ... other configuration
}

# Azure DevOps Agent with .NET image
module "azdo_agent" {
  source = "./azure/azure-devops-agent"
  
  docker_image = "fok666/azure-devops-agent:dotnet"
  vm_sku       = "Standard_D2s_v3"
  
  # ... other configuration
}
```

### Environment-Specific Recommendations

**Development**
```hcl
docker_image      = "fok666/github-runner:minimal"
use_spot_instances = true
min_instances     = 0  # Scale to zero
```

**Staging**
```hcl
docker_image      = "fok666/github-runner:latest"
use_spot_instances = true
min_instances     = 1
```

**Production**
```hcl
docker_image      = "fok666/github-runner:latest"
use_spot_instances = false  # Reliability over cost
min_instances     = 2       # High availability
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
docker_image = "fok666/github-runner:latest"
```
- ✅ Always up-to-date with latest features
- ✅ Automatic security patches
- ⚠️ May introduce unexpected changes

**Pinned Version** (Recommended for Production)
```hcl
docker_image = "fok666/github-runner:1.2.3"
```
- ✅ Reproducible builds
- ✅ Controlled updates
- ⚠️ Requires manual updates for security patches

**Pinned Minor Version** (Balanced Approach)
```hcl
docker_image = "fok666/github-runner:1.2"
```
- ✅ Automatic patch updates
- ✅ Controlled feature updates
- ✅ Good balance for most teams

## Customization

### Building Custom Variants

If your team needs specific tools not included in the standard images:

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

### Multi-Stage Builds

For maximum size optimization:

```dockerfile
# Build stage
FROM fok666/github-runner:golang AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Runtime stage
FROM fok666/github-runner:minimal
COPY --from=builder /app/myapp /usr/local/bin/
```

## Security Considerations

### Image Verification

All images are:
- ✅ Scanned for CVEs with Trivy
- ✅ Signed with Docker Content Trust
- ✅ Built from minimal base images (Ubuntu 22.04 LTS)
- ✅ Regularly updated with security patches

### Verification

```bash
# Verify image signature
export DOCKER_CONTENT_TRUST=1
docker pull fok666/github-runner:latest

# Scan for vulnerabilities
trivy image fok666/github-runner:latest
```

## Troubleshooting

### Wrong Architecture Pulled

If Docker pulls the wrong architecture:

```bash
# Explicitly specify platform
docker pull --platform linux/amd64 fok666/github-runner:latest
docker pull --platform linux/arm64 fok666/github-runner:latest
```

### Image Too Large

If disk space is constrained:

1. Use `minimal` variant
2. Enable image pruning in cloud-init/user-data:
```bash
# Add to runcmd
- docker system prune -af --volumes
```

### Missing Tools

If a required tool is missing:

1. Use a more complete image variant (`latest` vs `minimal`)
2. Build a custom image with the tool
3. Install the tool at runtime (slower):
```yaml
# cloud-init.yaml
runcmd:
  - apt-get update && apt-get install -y your-tool
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
- [terraform.tfvars.example](*/terraform.tfvars.example) - Configuration examples
