# Security Configuration

## Default Security Posture

All implementations follow secure-by-default principles:

| Feature | AWS | Azure | Default |
|---------|-----|-------|---------|
| SSH Access | ❌ | ❌ | Disabled |
| Public IP | ❌ | ✅* | Disabled (AWS) |
| Disk Encryption | ✅ | ✅ | Enabled |
| IMDSv2 | ✅ | N/A | Required |
| IAM/Identity | Least privilege | Managed Identity | Enabled |
| Network | Private subnets | VNet + NSG | Isolated |

\* Azure VMSS requires public IPs unless using NAT Gateway

## Network Security

### SSH Access

**Default: Disabled**

Enable only for debugging with specific CIDRs:

```hcl
# AWS
enable_ssh_access = true
ssh_cidr_blocks   = ["203.0.113.0/24"]  # Your IP range

# Azure
enable_ssh_access           = true
ssh_source_address_prefixes = ["203.0.113.0/24"]
```

**Recommended alternatives:**
- **AWS:** Systems Manager Session Manager (`aws ssm start-session`)
- **Azure:** Azure Bastion or Serial Console

### Egress Control

**Default: Allow all outbound** (required for CI/CD operations)

```hcl
egress_cidr_blocks = ["0.0.0.0/0"]  # AWS default
```

For restricted environments:

```hcl
# Restrict to specific networks (requires VPC endpoints, private registries)
egress_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]
```

**Note:** Restricting egress breaks CI/CD unless you provide:
- VPC endpoints for cloud services (S3, ECR, SSM, CloudWatch)
- Internal mirrors for package repositories (npm, pip, maven, etc.)
- Proxy servers for external access

### Public IP Addresses (AWS)

**Default: Disabled** (`associate_public_ip_address = false`)

Instances use NAT Gateway for outbound internet access. Enable public IPs only if necessary:

```hcl
associate_public_ip_address = true  # Not recommended
```

## Instance Metadata Security

### AWS IMDSv2

**Default: Required** (`enable_imdsv2 = true`)

Protects against SSRF attacks. Disabling is **not recommended**:

```hcl
enable_imdsv2 = false  # Insecure - legacy compatibility only
```

### Azure Managed Identity

System-assigned managed identity enabled by default for secure Azure resource access.

## Encryption

### AWS

- EBS volumes encrypted by default using AWS-managed keys
- Custom KMS keys can be configured via launch template

### Azure

- Managed disk encryption enabled by default
- Customer-managed keys configurable via:
  ```hcl
  disk_encryption_set_id = azurerm_disk_encryption_set.example.id
  ```

## IAM / Identity

### AWS IAM Roles

Least privilege policies included:
- `AmazonSSMManagedInstanceCore` - Session Manager access
- `CloudWatchAgentServerPolicy` - Logging/monitoring

No overly permissive policies (e.g., `AdministratorAccess`)

### Azure Managed Identity

System-assigned managed identity scoped to necessary resources only.

## Secrets Management

All sensitive variables marked `sensitive = true`:
- `gitlab_token`, `github_token`, `azp_token`

**Best practices:**
1. Never commit secrets to version control
2. Use secret management services:
   - AWS Secrets Manager / Parameter Store
   - Azure Key Vault
   - HashiCorp Vault
3. Rotate tokens regularly
4. Use minimal scope tokens

## Security Groups / NSG

### AWS Security Groups

**Ingress:** Denied by default (optional SSH from specific CIDRs)

**Egress:** Allow all by default (required for CI/CD)

### Azure Network Security Groups

**Inbound:** Denied by default (optional SSH from specific IPs)

**Outbound:** Allow all (required for runner operations)

## Production Checklist

Before deploying to production:

- [ ] SSH disabled or restricted to specific IPs
- [ ] Using private subnets (AWS) or VNet with NSG (Azure)
- [ ] IMDSv2 enabled (AWS)
- [ ] Disk encryption verified
- [ ] Secrets in secret management service
- [ ] IAM/managed identities follow least privilege
- [ ] Security groups/NSGs minimal and reviewed
- [ ] Logging/monitoring enabled
- [ ] Autoscaling limits configured
- [ ] Resource tags applied

## Monitoring

### AWS

- CloudWatch Logs for runner operations
- Consider: VPC Flow Logs, CloudTrail, GuardDuty

### Azure

- Azure Monitor for autoscale metrics
- Consider: NSG flow logs, Security Center, Sentinel

## Configuration Examples

### Development (More Permissive)

```hcl
enable_ssh_access      = true
ssh_cidr_blocks        = ["203.0.113.0/24"]  # Office IP
enable_imdsv2          = true  # Keep enabled
use_spot_instances     = true  # Cost savings
```

### Production (Secure)

```hcl
enable_ssh_access               = false
associate_public_ip_address     = false  # AWS
enable_imdsv2                   = true
use_spot_instances              = true  # With graceful shutdown

# Enable security features
enable_centralized_logging = true
enable_runner_monitoring   = true
```

### High-Security (Restricted)

```hcl
enable_ssh_access               = false
associate_public_ip_address     = false
enable_imdsv2                   = true
egress_cidr_blocks              = ["10.0.0.0/8", "172.16.0.0/12"]

# VPC endpoints required for AWS services
# Private registries required for Docker images
# Internal mirrors required for packages
```

## Incident Response

If security incident occurs:

1. **Isolate:** Update security groups to block access
2. **Investigate:** Review CloudWatch/Azure Monitor logs
3. **Rotate:** Rotate all tokens and credentials
4. **Update:** Apply security patches
5. **Review:** Update security configurations

## Security Reviews

Recommended frequency:
- **Weekly:** Review access logs and alerts
- **Monthly:** Rotate credentials
- **Quarterly:** Full security audit
- **Annually:** Penetration testing

## References

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
