# Cloud Architecture Documentation

## Overview

This document provides detailed architecture diagrams and explanations for the self-hosted DevOps runner infrastructure deployed on Azure and AWS. The architecture is designed for **cost optimization, high availability, security, and multi-cloud consistency**.

## Table of Contents

- [High-Level Architecture](#high-level-architecture)
- [Azure Implementation (VMSS)](#azure-implementation-vmss)
- [AWS Implementation (ASG)](#aws-implementation-asg)
- [Network Architecture](#network-architecture)
- [Autoscaling Mechanism](#autoscaling-mechanism)
- [Runner Lifecycle](#runner-lifecycle)
- [Security Architecture](#security-architecture)
- [Spot Instance Management](#spot-instance-management)
- [Multi-Cloud Comparison](#multi-cloud-comparison)
- [Cost Optimization Features](#cost-optimization-features)

---

## High-Level Architecture

### Conceptual Overview

```mermaid
graph TB
    subgraph "CI/CD Platform"
        A[GitLab/GitHub/Azure DevOps]
    end
    
    subgraph "Cloud Infrastructure"
        B[Auto Scaling Group/VMSS]
        C[Runner Instance 1]
        D[Runner Instance 2]
        E[Runner Instance N]
    end
    
    subgraph "Monitoring & Management"
        F[CloudWatch/Azure Monitor]
        G[Autoscale Rules]
        H[Spot Termination Monitor]
    end
    
    A -->|Job Queue| B
    B -->|Scale Up/Down| C
    B -->|Scale Up/Down| D
    B -->|Scale Up/Down| E
    C -->|Register & Execute| A
    D -->|Register & Execute| A
    E -->|Register & Execute| A
    
    F -->|CPU Metrics| G
    G -->|Trigger Scaling| B
    H -->|Graceful Shutdown| C
    H -->|Graceful Shutdown| D
    H -->|Graceful Shutdown| E
    
    style A fill:#e1f5ff
    style B fill:#fff4e1
    style F fill:#e8f5e9
```

### Key Components

1. **CI/CD Platform**: Source of build jobs (GitLab, GitHub Actions, Azure DevOps)
2. **Auto Scaling Infrastructure**: Dynamic compute resources (AWS ASG or Azure VMSS)
3. **Runner Instances**: Ephemeral VMs/instances executing CI/CD jobs
4. **Monitoring**: Metrics collection and alerting (CloudWatch, Azure Monitor)
5. **Autoscale Rules**: CPU-based scaling policies (scale 0-N based on demand)
6. **Spot Termination Monitoring**: Graceful shutdown handlers for cost-optimized instances

---

## Azure Implementation (VMSS)

### Azure Architecture Diagram

```mermaid
graph TB
    subgraph "Azure Cloud"
        subgraph "Resource Group"
            subgraph "Virtual Network (10.0.0.0/16)"
                SUBNET[Subnet 10.0.1.0/24]
                NSG[Network Security Group]
            end
            
            subgraph "Compute"
                VMSS[Virtual Machine Scale Set]
                VM1[Ubuntu 24.04 LTS<br/>+ Docker + Runner]
                VM2[Ubuntu 24.04 LTS<br/>+ Docker + Runner]
                VMN[Ubuntu 24.04 LTS<br/>+ Docker + Runner]
            end
            
            subgraph "Storage"
                DISK1[64GB StandardSSD<br/>Encrypted]
                DISK2[64GB StandardSSD<br/>Encrypted]
                DISKN[64GB StandardSSD<br/>Encrypted]
            end
            
            subgraph "Monitoring"
                AUTOSCALE[Autoscale Settings<br/>Min: 0, Max: 10<br/>CPU 70%/30%]
                MONITOR[Azure Monitor<br/>Metrics & Logs]
                IMDS[Instance Metadata<br/>Scheduled Events]
            end
            
            subgraph "Identity"
                MI[Managed Identity<br/>SystemAssigned]
            end
        end
        
        GITLAB[GitLab/GitHub/Azure DevOps]
    end
    
    VMSS --> VM1
    VMSS --> VM2
    VMSS --> VMN
    
    VM1 --> DISK1
    VM2 --> DISK2
    VMN --> DISKN
    
    VM1 -.->|Uses| MI
    VM2 -.->|Uses| MI
    VMN -.->|Uses| MI
    
    SUBNET --> NSG
    VM1 --> SUBNET
    VM2 --> SUBNET
    VMN --> SUBNET
    
    AUTOSCALE -->|Scale Decision| VMSS
    MONITOR -->|CPU Metrics| AUTOSCALE
    IMDS -->|Termination Events| VM1
    IMDS -->|Termination Events| VM2
    
    VM1 -->|Register & Run Jobs| GITLAB
    VM2 -->|Register & Run Jobs| GITLAB
    VMN -->|Register & Run Jobs| GITLAB
    
    style VMSS fill:#0078d4,color:#fff
    style GITLAB fill:#fc6d26
    style NSG fill:#ff6b6b
    style MI fill:#00d084
```

### Azure Components

#### Virtual Machine Scale Set (VMSS)
- **Purpose**: Autoscaling group of identical VMs
- **Configuration**:
  - Spot instances enabled by default (60-90% cost savings)
  - Flexible orchestration mode
  - Availability zones: 1, 2, 3 (high availability)
  - Scale: 0-N instances (cost optimization)

#### Networking
- **VNet**: Configurable CIDR (default: 10.0.0.0/16)
- **Subnet**: Runner subnet (default: 10.0.1.0/24)
- **NSG Rules**:
  - ❌ Inbound: Deny all (SSH disabled by default)
  - ✅ Outbound: Allow internet (required for CI/CD)

#### Storage
- **OS Disk**: 64GB StandardSSD_LRS (default, cost-optimized)
- **Encryption**: Platform-managed keys (enabled)
- **Caching**: ReadWrite for better performance

#### Monitoring
- **Azure Monitor**: CPU, memory, disk, network metrics
- **Autoscale Rules**:
  - Scale out: CPU > 70% for 5 minutes → Add 1 instance
  - Scale in: CPU < 30% for 10 minutes → Remove 1 instance
  - Cooldown: 3 minutes (scale out), 5 minutes (scale in)
- **Scheduled Events**: IMDS monitoring for spot termination

#### Identity & Access
- **Managed Identity**: System-assigned, no credentials stored
- **RBAC**: Minimal permissions (read metadata, write logs)

---

## AWS Implementation (ASG)

### AWS Architecture Diagram

```mermaid
graph TB
    subgraph "AWS Cloud"
        subgraph "VPC (10.0.0.0/16)"
            subgraph "Public Subnet (10.0.1.0/24)"
                NAT[NAT Gateway]
            end
            
            subgraph "Private Subnet (10.0.2.0/24)"
                SG[Security Group]
                EC2_1[EC2 Instance<br/>Ubuntu 24.04 LTS<br/>Docker + Runner]
                EC2_2[EC2 Instance<br/>Ubuntu 24.04 LTS<br/>Docker + Runner]
                EC2_N[EC2 Instance<br/>Ubuntu 24.04 LTS<br/>Docker + Runner]
            end
        end
        
        subgraph "Auto Scaling"
            ASG[Auto Scaling Group]
            LT[Launch Template<br/>Spot Configuration<br/>IMDSv2 Required]
            TS[Target Tracking Policy<br/>CPU 70%]
        end
        
        subgraph "Storage"
            EBS1[64GB gp3 EBS<br/>Encrypted]
            EBS2[64GB gp3 EBS<br/>Encrypted]
            EBSN[64GB gp3 EBS<br/>Encrypted]
        end
        
        subgraph "Monitoring"
            CW[CloudWatch<br/>Metrics & Logs]
            CWL[CloudWatch Logs<br/>Runner Logs]
            EC2META[EC2 Metadata<br/>Spot Termination]
        end
        
        subgraph "Identity"
            IAM[IAM Role<br/>Instance Profile]
            SSM[Systems Manager<br/>Session Manager]
        end
        
        GITLAB[GitLab/GitHub/Azure DevOps]
    end
    
    ASG -->|Manages| EC2_1
    ASG -->|Manages| EC2_2
    ASG -->|Manages| EC2_N
    
    LT -->|Template| ASG
    TS -->|Scale Decision| ASG
    
    EC2_1 --> EBS1
    EC2_2 --> EBS2
    EC2_N --> EBSN
    
    EC2_1 -.->|Assumes| IAM
    EC2_2 -.->|Assumes| IAM
    EC2_N -.->|Assumes| IAM
    
    IAM -->|Enables| SSM
    
    EC2_1 --> SG
    EC2_2 --> SG
    EC2_N --> SG
    
    SG -->|No Public IP| NAT
    NAT -->|Internet Access| EC2_1
    NAT -->|Internet Access| EC2_2
    NAT -->|Internet Access| EC2_N
    
    CW -->|CPU Metrics| TS
    EC2META -->|Termination Notice| EC2_1
    EC2META -->|Termination Notice| EC2_2
    
    EC2_1 -->|Logs| CWL
    EC2_2 -->|Logs| CWL
    
    EC2_1 -->|Register & Run Jobs| GITLAB
    EC2_2 -->|Register & Run Jobs| GITLAB
    EC2_N -->|Register & Run Jobs| GITLAB
    
    style ASG fill:#ff9900,color:#fff
    style GITLAB fill:#fc6d26
    style SG fill:#ff6b6b
    style IAM fill:#00d084
    style NAT fill:#4caf50
```

### AWS Components

#### Auto Scaling Group (ASG)
- **Purpose**: Autoscaling group of EC2 instances
- **Configuration**:
  - Spot instances enabled by default (60-90% cost savings)
  - Mixed instances policy for spot diversification
  - Availability zones: Multi-AZ (a, b, c)
  - Scale: 0-N instances (cost optimization)

#### Launch Template
- **Instance Type**: t3.medium (default, 2 vCPU, 4GB RAM)
- **AMI**: Ubuntu 24.04 LTS (latest)
- **User Data**: Runner installation and configuration script
- **Spot Configuration**: Max price, interruption behavior
- **IMDSv2**: Required (security best practice)

#### Networking
- **VPC**: Configurable CIDR (default: 10.0.0.0/16)
- **Private Subnet**: Runner instances (default: 10.0.2.0/24)
- **Public Subnet**: NAT Gateway (internet access)
- **Security Group Rules**:
  - ❌ Inbound: Deny all (SSH disabled by default)
  - ✅ Outbound: Allow all (0.0.0.0/0 for CI/CD operations)
- **No Public IPs**: Instances in private subnet, internet via NAT

#### Storage
- **EBS Volume**: 64GB gp3 (default, cost-optimized)
- **Encryption**: AWS-managed KMS keys (enabled)
- **IOPS**: 3000 baseline (gp3)
- **Throughput**: 125 MiB/s baseline

#### Monitoring & Autoscaling
- **CloudWatch Metrics**: CPU, network, disk, custom metrics
- **Target Tracking Policy**:
  - Target: 70% average CPU utilization
  - Scale out: When CPU > 70% for 2 data points (2 minutes)
  - Scale in: When CPU < 70% for 15 consecutive periods (15 minutes)
- **CloudWatch Logs**: Runner initialization and execution logs
- **Spot Termination**: 2-minute warning via EC2 metadata

#### Identity & Access
- **IAM Role**: Instance profile with minimal permissions
- **Policies**:
  - `AmazonSSMManagedInstanceCore` (Systems Manager access)
  - `CloudWatchAgentServerPolicy` (logging)
- **Session Manager**: SSH alternative (no keys required)

---

## Network Architecture

### Network Topology Comparison

```mermaid
graph TB
    subgraph "Azure Network Topology"
        subgraph "VNet (10.0.0.0/16)"
            AZ_SUBNET[Subnet 10.0.1.0/24]
            AZ_NSG[Network Security Group]
            AZ_VM1[VMSS Instance 1]
            AZ_VM2[VMSS Instance 2]
        end
        AZ_INTERNET[Internet]
    end
    
    subgraph "AWS Network Topology"
        subgraph "VPC (10.0.0.0/16)"
            subgraph "Public Subnet (10.0.1.0/24)"
                AWS_NAT[NAT Gateway]
                AWS_IGW[Internet Gateway]
            end
            subgraph "Private Subnet (10.0.2.0/24)"
                AWS_SG[Security Group]
                AWS_EC2_1[ASG Instance 1]
                AWS_EC2_2[ASG Instance 2]
            end
        end
        AWS_INTERNET[Internet]
    end
    
    AZ_VM1 --> AZ_SUBNET
    AZ_VM2 --> AZ_SUBNET
    AZ_SUBNET --> AZ_NSG
    AZ_NSG -->|Outbound Rules| AZ_INTERNET
    
    AWS_EC2_1 --> AWS_SG
    AWS_EC2_2 --> AWS_SG
    AWS_SG -->|Private Subnet| AWS_NAT
    AWS_NAT -->|Public Subnet| AWS_IGW
    AWS_IGW --> AWS_INTERNET
    
    style AZ_NSG fill:#ff6b6b
    style AWS_SG fill:#ff6b6b
    style AWS_NAT fill:#4caf50
    style AZ_INTERNET fill:#e1f5ff
    style AWS_INTERNET fill:#e1f5ff
```

### Network Security

#### Default Security Posture
| Feature | Azure | AWS | Rationale |
|---------|-------|-----|-----------|
| **SSH Access** | ❌ Disabled | ❌ Disabled | Reduces attack surface |
| **Public IP** | ✅ Required* | ❌ Not assigned | *Azure VMSS requires for internet unless NAT |
| **Inbound Traffic** | ❌ Deny all | ❌ Deny all | Zero-trust principle |
| **Outbound Traffic** | ✅ Allow internet | ✅ Allow internet | CI/CD operations require internet |
| **Network Isolation** | VNet isolation | VPC isolation | Defense in depth |

#### Secure Access Methods
- **Azure**: Azure Bastion (browser-based), Azure Serial Console
- **AWS**: AWS Systems Manager Session Manager (no SSH keys needed)
- **Both**: Centralized logging via CloudWatch/Azure Monitor

---

## Autoscaling Mechanism

### Autoscaling Flow

```mermaid
sequenceDiagram
    participant CW as CloudWatch/Azure Monitor
    participant AS as Autoscale Engine
    participant ASG as ASG/VMSS
    participant VM as Runner Instance
    participant CI as CI/CD Platform
    
    Note over CW: Collect CPU Metrics Every 1 Min
    
    CW->>AS: CPU > 70% for 5 minutes
    AS->>ASG: Trigger Scale Out (+1 instance)
    ASG->>VM: Launch new instance
    
    Note over VM: Cloud-Init/User-Data Executes
    VM->>VM: Install Docker
    VM->>VM: Configure Runner
    VM->>CI: Register Runner
    CI->>VM: Assign Job
    VM->>CI: Execute & Report Results
    
    Note over CW: CPU < 30% for 10 minutes
    CW->>AS: Low utilization detected
    AS->>ASG: Trigger Scale In (-1 instance)
    ASG->>VM: Graceful Shutdown (3 min timeout)
    VM->>CI: Unregister Runner
    VM->>VM: Stop containers
    VM->>VM: Terminate
    
    Note over ASG: Instance count decreases
```

### Autoscale Configuration

#### Azure VMSS Autoscale Rules

```hcl
Scale Out Rule:
- Metric: CPU Percentage
- Threshold: > 70%
- Time Window: 5 minutes
- Time Aggregation: Average
- Action: Increase count by 1
- Cooldown: 3 minutes

Scale In Rule:
- Metric: CPU Percentage
- Threshold: < 30%
- Time Window: 10 minutes (longer for stability)
- Time Aggregation: Average
- Action: Decrease count by 1
- Cooldown: 5 minutes
```

#### AWS Target Tracking Policy

```hcl
Target Tracking:
- Metric: CPU Utilization
- Target: 70% average
- Scale Out: When above target for 2 consecutive periods (2 min)
- Scale In: When below target for 15 consecutive periods (15 min)
- Instance Warmup: 180 seconds
- Cooldown: Not required (target tracking manages this)
```

### Scale-to-Zero Capability

```mermaid
graph LR
    A[No Jobs in Queue] -->|15 min idle| B[CPU < 30%]
    B -->|Scale In Policy| C[Remove Instance]
    C -->|Repeat| D{Instances > Min}
    D -->|Yes| C
    D -->|No: min_instances=0| E[Zero Instances]
    E -->|Cost: $0/hour for compute| F[Only pay for storage]
    
    G[New Job Arrives] -->|Queued| H[Scale Out Triggered]
    H -->|Launch Instance| I[Runner Registers]
    I -->|~3-5 minutes| J[Job Executes]
    
    style E fill:#4caf50,color:#fff
    style F fill:#4caf50,color:#fff
```

**Benefits**:
- **Cost**: Zero compute cost when idle (only storage: ~$5/mo)
- **Automatic**: No manual intervention required
- **Fast**: Scales up in 3-5 minutes when jobs arrive
- **Safe**: Configurable minimum (0 or higher) based on requirements

---

## Runner Lifecycle

### Runner Registration and Execution Flow

```mermaid
stateDiagram-v2
    [*] --> InstanceLaunch: ASG/VMSS scales up
    
    InstanceLaunch --> CloudInit: Cloud-init/User-data starts
    CloudInit --> DockerInstall: Install Docker
    DockerInstall --> RunnerPull: Pull runner image
    RunnerPull --> RunnerConfig: Configure runner
    RunnerConfig --> RunnerRegister: Register with CI/CD platform
    
    RunnerRegister --> Idle: Waiting for jobs
    Idle --> JobReceived: Job assigned
    JobReceived --> JobExecution: Execute job in Docker
    JobExecution --> JobComplete: Report results
    JobComplete --> Idle: Wait for next job
    
    Idle --> SpotWarning: Spot termination notice
    SpotWarning --> GracefulShutdown: Stop accepting jobs
    GracefulShutdown --> Unregister: Unregister from platform
    Unregister --> Terminate: Instance terminates
    
    Idle --> ScaleIn: Low CPU, scale-in triggered
    ScaleIn --> GracefulShutdown
    
    Terminate --> [*]
    
    note right of CloudInit
        180-240 seconds
        (instance warmup)
    end note
    
    note right of JobExecution
        Variable duration
        (job-dependent)
    end note
    
    note right of GracefulShutdown
        30-120 seconds
        (cleanup)
    end note
```

### Runner Container Architecture

```mermaid
graph TB
    subgraph "Runner Instance (VM/EC2)"
        subgraph "Host OS (Ubuntu 24.04)"
            DOCKER[Docker Engine]
            MONITOR[Monitoring Script]
            METADATA[Metadata Service Client]
        end
        
        subgraph "Runner Container (Privileged)"
            RUNNER[GitLab/GitHub/Azure DevOps Runner]
            DOCKER_CLIENT[Docker Client]
        end
        
        subgraph "Job Containers (DinD)"
            JOB1[Job Container 1]
            JOB2[Job Container 2]
            JOBN[Job Container N]
        end
    end
    
    RUNNER -->|Docker Socket| DOCKER_CLIENT
    DOCKER_CLIENT -->|/var/run/docker.sock| DOCKER
    DOCKER -->|Creates| JOB1
    DOCKER -->|Creates| JOB2
    DOCKER -->|Creates| JOBN
    
    MONITOR -->|Checks| METADATA
    METADATA -->|Termination Event| MONITOR
    MONITOR -->|Graceful Stop| RUNNER
    
    style RUNNER fill:#fc6d26
    style DOCKER fill:#2496ed
    style MONITOR fill:#4caf50
```

### Multi-Runner Configuration

```mermaid
graph TB
    subgraph "Instance (4 vCPU, 16GB RAM)"
        DOCKER[Docker Engine]
        
        subgraph "Runner Containers"
            R1[Runner 1<br/>concurrent=1]
            R2[Runner 2<br/>concurrent=1]
            R3[Runner 3<br/>concurrent=1]
            R4[Runner 4<br/>concurrent=1]
        end
    end
    
    CI[CI/CD Platform<br/>Job Queue]
    
    CI -->|Job 1| R1
    CI -->|Job 2| R2
    CI -->|Job 3| R3
    CI -->|Job 4| R4
    
    R1 -->|Executes in| DOCKER
    R2 -->|Executes in| DOCKER
    R3 -->|Executes in| DOCKER
    R4 -->|Executes in| DOCKER
    
    style CI fill:#e1f5ff
    style DOCKER fill:#2496ed
```

**Runner Count Strategy**:
- **Auto-detect (default)**: `runner_count_per_instance = 0` → Uses vCPU count
- **2 vCPU**: 2 runners (t3.medium, Standard_D2s_v3)
- **4 vCPU**: 4 runners (t3.xlarge, Standard_D4s_v3)
- **8 vCPU**: 8 runners (m5.2xlarge, Standard_D8s_v3)
- **Manual Override**: Set specific count based on workload

---

## Security Architecture

### Security Layers

```mermaid
graph TB
    subgraph "Layer 1: Network Security"
        NSG[Network Security Group/SG<br/>✅ Deny all inbound<br/>✅ Allow outbound to internet]
        PRIVATE[Private Subnet<br/>✅ No public IPs<br/>✅ Internet via NAT]
    end
    
    subgraph "Layer 2: Instance Security"
        SSH[SSH Access<br/>❌ Disabled by default]
        IMDS[Instance Metadata<br/>✅ IMDSv2 required (AWS)<br/>✅ Auth required]
        DISK[Disk Encryption<br/>✅ Enabled by default<br/>✅ Platform-managed keys]
    end
    
    subgraph "Layer 3: Identity & Access"
        IAM[IAM Role/Managed Identity<br/>✅ Least privilege<br/>✅ No stored credentials]
        SECRETS[Secrets Management<br/>✅ Marked sensitive<br/>✅ External stores recommended]
    end
    
    subgraph "Layer 4: Runtime Security"
        DOCKER[Docker Isolation<br/>✅ Container boundaries<br/>⚠️ Privileged for DinD]
        MONITOR[Security Monitoring<br/>✅ CloudWatch/Azure Monitor<br/>✅ Flow logs available]
    end
    
    subgraph "Layer 5: Compliance"
        AUDIT[Audit & Compliance<br/>✅ All actions logged<br/>✅ Immutable infrastructure]
        PATCH[Patching Strategy<br/>✅ Ephemeral instances<br/>✅ Latest OS on launch]
    end
    
    style NSG fill:#ff6b6b
    style SSH fill:#ff6b6b
    style DISK fill:#4caf50
    style IAM fill:#4caf50
    style MONITOR fill:#4caf50
```

### Security Threat Model

```mermaid
graph LR
    subgraph "Potential Threats"
        T1[Unauthorized Access]
        T2[Data Exfiltration]
        T3[Credential Theft]
        T4[Lateral Movement]
        T5[Supply Chain]
    end
    
    subgraph "Mitigations"
        M1[SSH Disabled<br/>IMDSv2 Required<br/>No Public IPs]
        M2[Encrypted Disks<br/>Ephemeral Storage<br/>Network Isolation]
        M3[Managed Identity<br/>No Stored Secrets<br/>Least Privilege IAM]
        M4[Network Segmentation<br/>Security Groups<br/>Private Subnets]
        M5[Verified Images<br/>Latest Patches<br/>Immutable Infra]
    end
    
    T1 -.->|Prevented by| M1
    T2 -.->|Prevented by| M2
    T3 -.->|Prevented by| M3
    T4 -.->|Prevented by| M4
    T5 -.->|Prevented by| M5
    
    style T1 fill:#ffebee
    style T2 fill:#ffebee
    style T3 fill:#ffebee
    style T4 fill:#ffebee
    style T5 fill:#ffebee
    style M1 fill:#e8f5e9
    style M2 fill:#e8f5e9
    style M3 fill:#e8f5e9
    style M4 fill:#e8f5e9
    style M5 fill:#e8f5e9
```

---

## Spot Instance Management

### Spot Termination Handling

```mermaid
sequenceDiagram
    participant AWS as AWS/Azure
    participant MON as Termination Monitor
    participant RUN as Runner Container
    participant CI as CI/CD Platform
    participant JOB as Running Job
    
    Note over AWS: Spot capacity needed elsewhere
    AWS->>MON: Termination notice (2 min warning)
    MON->>MON: Log termination event
    
    alt Job in Progress
        MON->>RUN: Check container status
        RUN->>JOB: Job still executing
        MON->>MON: Wait for job completion (max 90s)
        JOB->>RUN: Job completes
        RUN->>CI: Report success
    else No Job Running
        MON->>RUN: Immediate shutdown
    end
    
    MON->>RUN: Send SIGTERM
    RUN->>CI: Unregister runner
    RUN->>RUN: Stop accepting new jobs
    RUN->>RUN: Cleanup containers
    
    Note over MON: 30 seconds cleanup
    MON->>AWS: Ready for termination
    AWS->>AWS: Terminate instance
    
    Note over CI: Job marked incomplete (if timeout)
    CI->>CI: Re-queue job to another runner
```

### Spot vs On-Demand Decision Matrix

```mermaid
graph TD
    START[Choose Instance Type] --> COST{Cost Priority?}
    
    COST -->|High| SPOT[Use Spot Instances]
    COST -->|Low| AVAIL{Availability Critical?}
    
    AVAIL -->|Yes| OD[Use On-Demand]
    AVAIL -->|No| SPOT
    
    SPOT --> DIVS{Diversification?}
    DIVS -->|AWS| MIX[Mixed Instances Policy<br/>Multiple instance types]
    DIVS -->|Azure| FLEX[Flexible orchestration<br/>Multiple zones]
    
    MIX --> SAVE[60-90% Savings<br/>Good availability]
    FLEX --> SAVE
    
    OD --> STABLE[100% Availability<br/>Higher cost]
    
    style SPOT fill:#4caf50,color:#fff
    style SAVE fill:#4caf50,color:#fff
    style OD fill:#ff9800,color:#fff
    style STABLE fill:#ff9800,color:#fff
```

### Spot Instance Availability Strategy

**AWS**:
- **Mixed Instances Policy**: Supports multiple instance types
- **Example**: `["t3.medium", "t3a.medium", "t2.medium", "t3.small"]`
- **Benefit**: If t3.medium spot unavailable, ASG tries t3a.medium, then t2.medium, etc.
- **Result**: Higher spot availability, fewer interruptions

**Azure**:
- **Flexible Orchestration**: Automatically tries different zones
- **Availability Zones**: 1, 2, 3
- **Benefit**: If zone 1 spot unavailable, tries zone 2, then zone 3
- **Result**: Higher spot availability across regions

---

## Multi-Cloud Comparison

### Feature Parity Matrix

| Feature | Azure (VMSS) | AWS (ASG) | Notes |
|---------|-------------|-----------|-------|
| **Autoscaling** | ✅ Azure Monitor | ✅ Target Tracking | Both CPU-based, scale 0-N |
| **Spot Instances** | ✅ Spot Priority | ✅ Spot Instances | 60-90% savings on both |
| **Scale to Zero** | ✅ min=0 | ✅ min=0 | Cost optimization feature |
| **Availability Zones** | ✅ Zones 1,2,3 | ✅ Multi-AZ | High availability on both |
| **Instance Metadata** | ✅ IMDS | ✅ IMDSv2 | Spot termination monitoring |
| **Managed Identity** | ✅ System-Assigned | ✅ IAM Role | No stored credentials |
| **Disk Encryption** | ✅ Platform Keys | ✅ AWS KMS | Enabled by default |
| **Network Isolation** | ✅ NSG + VNet | ✅ SG + VPC | Private by default |
| **SSH Access** | ❌ Disabled | ❌ Disabled | Secure by default |
| **Secure Access** | ✅ Azure Bastion | ✅ Session Manager | No SSH keys needed |
| **Monitoring** | ✅ Azure Monitor | ✅ CloudWatch | Metrics + logs |
| **Cost** | ~$13-31/mo spot | ~$13-31/mo spot | Similar economics |

### Architecture Decision Tree

```mermaid
graph TD
    START[Choose Cloud Platform] --> EXISTING{Existing Infrastructure?}
    
    EXISTING -->|Azure| AZ[Deploy to Azure<br/>Use VMSS]
    EXISTING -->|AWS| AW[Deploy to AWS<br/>Use ASG]
    EXISTING -->|Both| MULTI[Multi-Cloud Deployment]
    EXISTING -->|Neither| CHOICE[Evaluate Options]
    
    CHOICE --> TEAM{Team Expertise?}
    TEAM -->|Azure| AZ
    TEAM -->|AWS| AW
    TEAM -->|Both| COST{Cost Priority?}
    
    COST -->|Optimize| SPOT[Use Spot Instances<br/>Both clouds ~same cost]
    COST -->|Stability| COMPARE[Compare Regional Pricing]
    
    SPOT --> DEPLOY[Deploy IaC]
    COMPARE --> DEPLOY
    
    MULTI --> CICD{CI/CD Platform?}
    CICD -->|GitLab.com| EITHER[Either cloud works]
    CICD -->|Self-hosted| SAME[Deploy to same cloud]
    
    style AZ fill:#0078d4,color:#fff
    style AW fill:#ff9900,color:#fff
    style MULTI fill:#9c27b0,color:#fff
    style DEPLOY fill:#4caf50,color:#fff
```

---

## Cost Optimization Features

### Cost Breakdown (Monthly)

```mermaid
pie title Monthly Cost per Runner Instance (Spot)
    "Compute (Spot)" : 21
    "Storage (64GB)" : 5
    "Network (Egress)" : 2
    "Monitoring" : 1
```

```mermaid
pie title Monthly Cost per Runner Instance (On-Demand)
    "Compute (On-Demand)" : 70
    "Storage (64GB)" : 5
    "Network (Egress)" : 2
    "Monitoring" : 1
```

### Cost Optimization Flow

```mermaid
graph TB
    START[Runner Deployment] --> SPOT{Use Spot?}
    
    SPOT -->|Yes| S1[60-90% Savings<br/>on Compute]
    SPOT -->|No| OD[Full On-Demand Price]
    
    S1 --> SCALE{Scale to Zero?}
    SCALE -->|Yes: min=0| ZERO[Zero Cost When Idle<br/>Only storage: ~$5/mo]
    SCALE -->|No: min=2| ALWAYS[Always Running<br/>~$26-62/mo for 2 instances]
    
    ZERO --> DISK{Optimize Disk?}
    ALWAYS --> DISK
    OD --> DISK
    
    DISK -->|64GB Standard| D1[~$5/mo<br/>Sufficient for most]
    DISK -->|128GB Standard| D2[~$10/mo<br/>Large builds]
    DISK -->|64GB Premium| D3[~$10/mo<br/>High IOPS]
    
    D1 --> TOTAL[Total Monthly Cost]
    D2 --> TOTAL
    D3 --> TOTAL
    
    style SPOT fill:#4caf50,color:#fff
    style ZERO fill:#4caf50,color:#fff
    style D1 fill:#4caf50,color:#fff
    style OD fill:#ff9800,color:#fff
```

### Cost Comparison Table

| Configuration | Compute/Month | Storage/Month | Total/Month | vs On-Demand |
|---------------|---------------|---------------|-------------|--------------|
| **Spot + Scale-to-Zero** (Recommended) | $0 (idle) | $5 | **$5** (idle) | -95% |
| **Spot + min=1** | $21 | $5 | **$26** | -66% |
| **Spot + min=2** | $42 | $10 | **$52** | -66% |
| **On-Demand + min=1** | $70 | $5 | **$75** | Baseline |
| **On-Demand + min=2** | $140 | $10 | **$150** | Baseline |

**Notes**:
- Costs based on Standard_D2s_v3 (Azure) / t3.medium (AWS)
- Storage: 64GB StandardSSD/gp3
- Network costs not included (typically $1-5/mo)
- Spot pricing varies by region and availability

### Resource Right-Sizing Guide

```mermaid
graph LR
    subgraph "Workload Analysis"
        W1[Small Projects<br/>Infrequent Builds]
        W2[Standard CI/CD<br/>Docker Builds]
        W3[Large Monorepos<br/>Parallel Tests]
        W4[Compute Intensive<br/>ML/Compilation]
    end
    
    subgraph "Instance Recommendations"
        I1[2 vCPU, 4-8 GB<br/>$7-15/mo spot]
        I2[4 vCPU, 16 GB<br/>$30-50/mo spot]
        I3[8 vCPU, 32 GB<br/>$60-100/mo spot]
        I4[16 vCPU, 64 GB<br/>$120-200/mo spot]
    end
    
    W1 --> I1
    W2 --> I2
    W3 --> I3
    W4 --> I4
    
    style W1 fill:#e3f2fd
    style W2 fill:#e3f2fd
    style W3 fill:#e3f2fd
    style W4 fill:#e3f2fd
    style I1 fill:#c8e6c9
    style I2 fill:#fff9c4
    style I3 fill:#ffccbc
    style I4 fill:#ffccbc
```

---

## Deployment Options

### Deployment Patterns

```mermaid
graph TB
    subgraph "Pattern 1: Development"
        DEV_CONFIG[Configuration:<br/>• Spot instances<br/>• min=0, max=3<br/>• StandardSSD 64GB<br/>• Single region]
        DEV_COST[Cost: ~$5-30/mo]
        DEV_USE[Use Case: Personal projects,<br/>testing, infrequent builds]
    end
    
    subgraph "Pattern 2: Production"
        PROD_CONFIG[Configuration:<br/>• Spot instances<br/>• min=2, max=20<br/>• StandardSSD 64GB<br/>• Multi-zone]
        PROD_COST[Cost: ~$52-200/mo]
        PROD_USE[Use Case: Team projects,<br/>CI/CD, moderate scale]
    end
    
    subgraph "Pattern 3: High Availability"
        HA_CONFIG[Configuration:<br/>• On-Demand<br/>• min=3, max=50<br/>• Premium 128GB<br/>• Multi-region]
        HA_COST[Cost: ~$300-1000+/mo]
        HA_USE[Use Case: Mission critical,<br/>SLA requirements, enterprise]
    end
    
    style DEV_CONFIG fill:#c8e6c9
    style PROD_CONFIG fill:#fff9c4
    style HA_CONFIG fill:#ffccbc
```

---

## Summary

### Key Architectural Principles

1. **Cost-First Design**
   - Spot instances by default (60-90% savings)
   - Scale-to-zero capability (min_instances = 0)
   - Right-sized defaults (2 vCPU, 64GB disk)
   - Auto-detection of optimal runner count

2. **Security-First Design**
   - SSH disabled by default
   - No public IPs on AWS (private subnets + NAT)
   - IMDSv2 required (AWS)
   - Encrypted disks
   - Managed identities (no stored credentials)

3. **Cloud-Agnostic Patterns**
   - Consistent configuration across Azure and AWS
   - Feature parity between implementations
   - Reusable Terraform modules
   - Same operational patterns

4. **Production-Ready**
   - Comprehensive monitoring
   - Graceful spot termination handling
   - Autoscaling with scale-to-zero
   - Multi-zone high availability
   - Ephemeral and immutable

5. **Developer-Friendly**
   - Simple configuration (minimal required variables)
   - Clear documentation with cost implications
   - Pre-configured security defaults
   - Easy customization for specific needs

### Next Steps

- Review [QUICKSTART.md](QUICKSTART.md) for deployment instructions
- Check [SECURITY.md](SECURITY.md) for security best practices
- See [TESTING_GUIDE.md](TESTING_GUIDE.md) for validation procedures
- Read [TERRAFORM_TESTING.md](docs/TERRAFORM_TESTING.md) for automated tests

---

**Last Updated**: January 2026  
**Version**: 1.1  
**Maintained By**: Infrastructure Team
