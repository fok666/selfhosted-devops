# Security Best Practices

This document outlines the security features and best practices implemented in this infrastructure.

## 🔒 Security Features

### Network Security

#### SSH Access (Disabled by Default)
- **Default**: SSH access is **disabled** for all implementations
- **Configuration**: Can be enabled with specific CIDR restrictions

**AWS Implementations:**
```hcl
# Enable SSH only from specific IP ranges
enable_ssh_access = true
ssh_cidr_blocks   = ["10.0.0.0/8"]  # Replace with your specific IPs
```

**Azure Implementations:**
```hcl
# Enable SSH only from specific IP ranges
enable_ssh_access           = true
ssh_source_address_prefixes = ["10.0.0.0/8"]  # Replace with your specific IPs
```

**⚠️ Security Consequences of SSH Access:**

When SSH is enabled with `0.0.0.0/0`:
- ✗ CRITICAL SECURITY RISK - Never use in production!
- ✗ Exposed to brute force attacks globally
- ✗ High risk of credential stuffing attacks
- ✗ Target for automated vulnerability scanners
- ✗ Non-compliant with security frameworks
- ✗ The configuration includes validation to prevent this

When SSH is enabled with specific CIDR blocks:
- ⚠️ Limited exposure to defined networks only
- ⚠️ Still requires strong SSH key management
- ⚠️ Consider VPN or bastion host instead
- ⚠️ Ensure regular security patching
- ⚠️ Monitor for failed login attempts

When SSH is disabled (default):
- ✓ No direct access attack vector
- ✓ Forces use of secure alternatives (AWS Systems Manager, Azure Bastion)
- ✓ Compliant with zero-trust security model
- ✓ Better audit trail via session logging
- ✓ No SSH key management overhead
- ✓ Reduces attack surface significantly

**Recommended Alternatives to SSH:**
- **AWS**: Use AWS Systems Manager Session Manager
  ```bash
  aws ssm start-session --target <instance-id>
  ```
- **Azure**: Use Azure Bastion for secure browser-based access
- **Both**: Deploy jump/bastion hosts in secured subnets

#### Security Groups / Network Security Groups
- **Egress**: Allows outbound internet access (required for CI/CD operations)
- **Ingress**: No inbound access by default (except optional SSH with restrictions)
- **Principle**: Deny by default, allow only what's necessary

### Encryption

#### AWS
- **EBS Volumes**: Encryption at rest enabled by default (`encrypted = true`)
- **Type**: Uses AWS-managed keys by default
- **Custom KMS**: Can be configured via launch template if needed

#### Azure
- **Managed Disks**: Platform-managed encryption enabled by default
- **Customer-Managed Keys**: Can be configured via optional parameters:
  ```hcl
  disk_encryption_set_id                = azurerm_disk_encryption_set.example.id
  secure_vm_disk_encryption_set_id     = azurerm_disk_encryption_set.secure.id
  ```

### Instance Metadata Security

#### AWS IMDSv2 (Instance Metadata Service v2)
- **Default**: IMDSv2 **required** (`enable_imdsv2 = true`)
- **Benefit**: Prevents SSRF (Server-Side Request Forgery) attacks and unauthorized metadata access
- **Configuration**: Available in all AWS implementations:
  ```hcl
  # aws/azure-devops-agent/terraform.tfvars
  # aws/github-runner/terraform.tfvars
  # aws/gitlab-runner/terraform.tfvars
  enable_imdsv2 = false  # NOT RECOMMENDED - Use only for legacy compatibility
  ```

**⚠️ Security Consequences of Disabling IMDSv2:**

When `enable_imdsv2 = false`:
- ✗ Instance metadata is accessible via simple HTTP GET requests
- ✗ SSRF vulnerabilities in applications can be exploited to steal IAM credentials
- ✗ No session authentication required for metadata access
- ✗ Attackers can potentially pivot to other AWS resources using stolen credentials
- ✗ Non-compliant with many security frameworks (CIS, NIST)

When `enable_imdsv2 = true` (default):
- ✓ Requires PUT request to obtain session token before accessing metadata
- ✓ Session tokens have TTL (time-to-live) limiting exposure window
- ✓ Protects against SSRF attacks via hop limits
- ✓ Compliant with AWS security best practices
- ✓ Meets requirements for SOC 2, ISO 27001, and similar frameworks

#### Azure Instance Metadata
- **Access**: Limited to instance only
- **Authentication**: Uses system-assigned managed identity where applicable

### IAM / Identity Management

#### AWS IAM Roles
- **Principle of Least Privilege**: Roles include only necessary permissions
- **Included Policies**:
  - `AmazonSSMManagedInstanceCore` - For Systems Manager access (no SSH needed)
  - `CloudWatchAgentServerPolicy` - For logging and monitoring
- **No**: Overly permissive policies like `AdministratorAccess`

#### Azure Managed Identity
- **Type**: System-assigned managed identity enabled
- **Scope**: Limited to necessary Azure resources
- **No**: Service principal credentials stored on VMs

### Network Isolation

#### Public IP Addresses
- **AWS Default**: No public IPs assigned (`associate_public_ip_address = false`)
- **Configuration**: Available in all AWS implementations if needed:
  ```hcl
  # aws/azure-devops-agent/terraform.tfvars
  # aws/github-runner/terraform.tfvars
  # aws/gitlab-runner/terraform.tfvars
  associate_public_ip_address = true  # USE WITH CAUTION
  ```

**⚠️ Security Consequences of Public IP Addresses:**

When `associate_public_ip_address = true`:
- ✗ Instances are directly exposed to the internet
- ✗ Increased attack surface for port scanning and brute force attacks
- ✗ Higher risk of DDoS attacks
- ✗ More difficult to implement centralized security controls
- ✗ Harder to audit and monitor network traffic
- ✗ Each instance becomes an independent internet endpoint

When `associate_public_ip_address = false` (default):
- ✓ Instances only accessible within VPC (defense in depth)
- ✓ Reduced attack surface
- ✓ Centralized outbound control via NAT Gateway
- ✓ Easier to implement network security monitoring
- ✓ Better compliance with network isolation requirements
- ✓ Simplified network security group rules

**Recommended Architecture for Internet Access:**
Instead of public IPs, use:
1. **NAT Gateway**: For outbound internet access from private subnets
2. **VPC Endpoints**: For AWS service access without internet
3. **AWS PrivateLink**: For accessing third-party SaaS securely

Example with NAT Gateway:
```hcl
# Your runners get internet access via NAT Gateway
# without being directly exposed
associate_public_ip_address = false  # Secure default
# Ensure your VPC has NAT Gateway configured
```

#### Private Subnets
- **AWS**: Supports deployment in private subnets with NAT Gateway
- **Azure**: VNet integration with service endpoints recommended

### Secrets Management

#### Sensitive Variables
All tokens and secrets are marked as `sensitive = true`:
- `github_token`
- `gitlab_token`
- `azp_token` (Azure DevOps)

#### Best Practices
1. **Never commit secrets** to version control
2. **Use environment variables** or secret management services:
   - AWS Secrets Manager / Parameter Store
   - Azure Key Vault
   - HashiCorp Vault
3. **Rotate tokens** regularly
4. **Use minimal scope** tokens (e.g., agent registration only)

## 🛡️ Security Configurations

### Production Deployment Checklist

- [ ] SSH access disabled or restricted to specific IPs
- [ ] Using private subnets with NAT Gateway
- [ ] IMDSv2 enabled (AWS)
- [ ] Disk encryption enabled
- [ ] Secrets stored in secret management service
- [ ] IAM roles follow least privilege
- [ ] Security groups/NSGs reviewed and minimal
- [ ] Monitoring and logging enabled
- [ ] Auto-scaling limits configured appropriately
- [ ] Spot instances configured with graceful shutdown
- [ ] Tags applied for resource tracking

### Monitoring & Compliance

#### AWS CloudWatch
- Detailed monitoring enabled by default
- Logs sent to CloudWatch Logs
- Consider enabling:
  - VPC Flow Logs
  - CloudTrail for API auditing
  - GuardDuty for threat detection

#### Azure Monitor
- Auto-scale metrics collected
- Consider enabling:
  - Network Security Group flow logs
  - Azure Security Center
  - Azure Sentinel for SIEM

## 🔐 Secure by Default

All implementations follow security best practices by default:

| Feature | AWS | Azure | Default |
|---------|-----|-------|---------|
| SSH Access | ❌ | ❌ | Disabled |
| Public IP | ❌ | ✅* | Disabled (AWS) |
| Disk Encryption | ✅ | ✅ | Enabled |
| IMDSv2 | ✅ | N/A | Required |
| Managed Identity | ✅ | ✅ | Enabled |
| Spot Instances | ✅ | ✅ | Enabled** |

\* Azure VMSS requires public IP for outbound internet unless using NAT Gateway  
\** Can be disabled for on-demand instances only

## 📝 Configuration Flexibility

While secure by default, all security settings can be configured:

```hcl
# Example: Enable SSH for development environment
module "github_runner_asg" {
  # ... other configuration ...
  
  # Security settings
  enable_ssh_access = true
  ssh_cidr_blocks   = ["203.0.113.0/24"]  # Your office IP range
  enable_imdsv2     = true                 # Keep IMDSv2 enabled
  
  # Optional: Enable public IP if needed
  associate_public_ip_address = true
  
  # Use on-demand instead of spot for stability
  use_spot_instances = false
}
```

## 🚨 Security Incident Response

If a security incident occurs:

1. **Isolate**: Update security groups to block access
2. **Investigate**: Check CloudWatch/Azure Monitor logs
3. **Rotate**: Rotate all tokens and credentials
4. **Update**: Apply security patches and updates
5. **Review**: Review and update security configurations

## 📚 Additional Resources

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns)
- [OWASP Cloud Security](https://owasp.org/www-project-cloud-security/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

## 🔄 Regular Security Reviews

Recommended frequency:
- **Weekly**: Review access logs and alerts
- **Monthly**: Review and rotate credentials
- **Quarterly**: Full security audit and compliance check
- **Annually**: Penetration testing and vulnerability assessment
