#!/bin/bash
# Azure DevOps Agent User Data Script
# This script sets up a self-hosted Azure Pipelines agent with Docker-in-Docker support

# shellcheck disable=SC2154
# Note: Variables like azp_url, azp_token, azp_pool are Terraform template variables

set -e
exec > >(tee /var/log/azdevops-agent-init.log)
exec 2>&1

echo "========================================="
echo "Azure DevOps Agent Initialization"
echo "Started at: $(date)"
echo "========================================="

# Environment variables (passed from Terraform)
AZP_URL="${azp_url}"
AZP_TOKEN="${azp_token}"
AZP_POOL="${azp_pool}"
AZP_AGENT_NAME="${azp_agent_name}-$(hostname)"

# Validate required variables
if [ -z "$AZP_URL" ] || [ -z "$AZP_TOKEN" ] || [ -z "$AZP_POOL" ]; then
  echo "ERROR: Missing required environment variables"
  echo "AZP_URL=$AZP_URL"
  echo "AZP_TOKEN=***"
  echo "AZP_POOL=$AZP_POOL"
  exit 1
fi

echo "Configuration:"
echo "  AZP_URL: $AZP_URL"
echo "  AZP_POOL: $AZP_POOL"
echo "  AZP_AGENT_NAME: $AZP_AGENT_NAME"

# Update system
echo "Updating system packages..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install dependencies
echo "Installing dependencies..."
apt-get install -y \
  docker.io \
  curl \
  jq \
  wget \
  git \
  unzip \
  ca-certificates \
  software-properties-common

# Configure Docker
echo "Configuring Docker..."
systemctl enable docker
systemctl start docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
timeout 60 bash -c 'until docker info >/dev/null 2>&1; do sleep 2; done'

# Create work directory
echo "Creating work directory..."
mkdir -p /azp/_work
chown -R ubuntu:ubuntu /azp

# Create agent start script
echo "Creating agent start script..."
cat > /usr/local/bin/start_azdevops_agent.sh << 'AGENT_START_SCRIPT'
#!/bin/bash
set -e

echo "Starting Azure DevOps Agent(s)..."

AZP_URL="${azp_url}"
AZP_TOKEN="${azp_token}"
AZP_POOL="${azp_pool}"
AZP_AGENT_NAME_PREFIX="${azp_agent_name}"
AGENT_COUNT="${agent_count}"

# Production Features Configuration
ENABLE_CACHE="${enable_distributed_cache}"
CACHE_S3_BUCKET="${cache_s3_bucket_name}"
CACHE_S3_REGION="${cache_s3_region}"
CACHE_S3_PREFIX="${cache_s3_prefix}"
CACHE_SHARED="${cache_shared}"
ENABLE_LOGGING="${enable_centralized_logging}"
CLOUDWATCH_LOG_GROUP="${cloudwatch_log_group_name}"
CLOUDWATCH_LOG_REGION="${cloudwatch_log_region}"
ENABLE_MONITORING="${enable_agent_monitoring}"
METRICS_PORT="${metrics_port}"

# Auto-detect agent count based on CPU count if agent_count is 0
if [ "$AGENT_COUNT" = "0" ]; then
  CPU_COUNT=$(nproc)
  # Scale agent count based on available CPUs:
  # 1-2 CPUs: 1 agent, 3-4 CPUs: 2 agents, 5-8 CPUs: 3 agents
  # 9-16 CPUs: 4 agents, 17+ CPUs: CPU_COUNT / 4 (rounded up)
  if [ $CPU_COUNT -le 2 ]; then
    AGENT_COUNT=1
  elif [ $CPU_COUNT -le 4 ]; then
    AGENT_COUNT=2
  elif [ $CPU_COUNT -le 8 ]; then
    AGENT_COUNT=3
  elif [ $CPU_COUNT -le 16 ]; then
    AGENT_COUNT=4
  else
    AGENT_COUNT=$(( (CPU_COUNT + 3) / 4 ))
  fi
  echo "Auto-detected $CPU_COUNT CPUs, will run $AGENT_COUNT agents"
fi

# Calculate CPU limit per agent
CPU_COUNT=$(nproc)
MAX_CPU=$((CPU_COUNT / AGENT_COUNT))
[ $MAX_CPU -lt 1 ] && MAX_CPU=1

# Configure distributed cache if enabled
CACHE_ENV_VARS=""
if [ "$ENABLE_CACHE" = "true" ]; then
  echo "Configuring distributed cache (S3)..."
  CACHE_ENV_VARS="-e CACHE_ENABLED=true \
    -e CACHE_TYPE=s3 \
    -e AWS_S3_BUCKET=$CACHE_S3_BUCKET \
    -e AWS_REGION=$CACHE_S3_REGION \
    -e AWS_S3_PREFIX=$CACHE_S3_PREFIX \
    -e CACHE_SHARED=$CACHE_SHARED"
  echo "  Cache S3 bucket: $CACHE_S3_BUCKET"
  echo "  Cache S3 region: $CACHE_S3_REGION"
  echo "  Cache S3 prefix: $CACHE_S3_PREFIX"
  echo "  Shared cache: $CACHE_SHARED"
fi

# Configure monitoring if enabled
MONITORING_ENV_VARS=""
MONITORING_PORT=""
if [ "$ENABLE_MONITORING" = "true" ]; then
  echo "Enabling agent monitoring (Prometheus metrics)..."
  MONITORING_ENV_VARS="-e METRICS_ENABLED=true -e METRICS_PORT=$METRICS_PORT"
  MONITORING_PORT="-p $METRICS_PORT:$METRICS_PORT"
  echo "  Metrics port: $METRICS_PORT"
fi

echo "Starting $AGENT_COUNT Azure DevOps agent(s)..."

# Start multiple agent containers
for A in $(seq 1 $AGENT_COUNT); do
  AZP_AGENT_NAME="$AZP_AGENT_NAME_PREFIX-$(hostname)-$A"
  WORK_DIR="/azp/agent$A/_work"
  CONTAINER_NAME="azdevops-agent-$A"
  
  mkdir -p "$WORK_DIR"
  
  echo "Starting agent $A/$AGENT_COUNT: $AZP_AGENT_NAME"
  
  if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "  Removing existing container: $CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true
  fi
  
  docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    --cpus="$MAX_CPU" \
    -e AZP_URL="$AZP_URL" \
    -e AZP_TOKEN="$AZP_TOKEN" \
    -e AZP_POOL="$AZP_POOL" \
    -e AZP_AGENT_NAME="$AZP_AGENT_NAME" \
    -e AZP_WORK="/_work" \
    $CACHE_ENV_VARS \
    $MONITORING_ENV_VARS \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$WORK_DIR":/_work \
    $MONITORING_PORT \
    --privileged \
    fok666/azuredevops:latest
  
  echo "  Container $CONTAINER_NAME started successfully"
done

echo "All agents started successfully!"

# Install and configure CloudWatch Agent if centralized logging is enabled
if [ "$ENABLE_LOGGING" = "true" ]; then
  echo "Installing Amazon CloudWatch Agent for centralized logging..."
  wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
  dpkg -i amazon-cloudwatch-agent.deb
  
  # Create CloudWatch agent configuration
  cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'CLOUDWATCH_CONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/azdevops-agent-init.log",
            "log_group_name": "${cloudwatch_log_group_name}",
            "log_stream_name": "{instance_id}/azdevops-agent-init.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "${cloudwatch_log_group_name}",
            "log_stream_name": "{instance_id}/syslog",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CLOUDWATCH_CONFIG
  
  # Start CloudWatch agent
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
  
  echo "CloudWatch Agent installed and configured"
fi

AGENT_START_SCRIPT

chmod +x /usr/local/bin/start_azdevops_agent.sh

# Create agent stop script
echo "Creating agent stop script..."
cat > /usr/local/bin/stop_azdevops_agent.sh << 'AGENT_STOP_SCRIPT'
#!/bin/bash
echo "Stopping Azure DevOps Agent gracefully..."

# Get all agent containers
CONTAINERS=$(docker ps --filter "name=azdevops-agent" --format "{{.ID}}")

if [ -z "$CONTAINERS" ]; then
  echo "No agent containers running"
  exit 0
fi

# Stop each container gracefully
for CONTAINER in $CONTAINERS; do
  echo "Stopping container: $CONTAINER"
  docker stop -t 60 "$CONTAINER" || true
  docker rm "$CONTAINER" || true
done

echo "All agents stopped"
AGENT_STOP_SCRIPT

chmod +x /usr/local/bin/stop_azdevops_agent.sh

# Create EC2 Spot Termination monitor
echo "Creating spot termination monitor..."
cat > /usr/local/bin/ec2_monitor.sh << 'EC2_MONITOR_SCRIPT'
#!/bin/bash
# Monitor EC2 Instance Metadata for spot instance termination

METADATA_ENDPOINT="http://169.254.169.254/latest/meta-data/spot/instance-action"
LOG_FILE="/var/log/ec2_monitor.log"

while true; do
  # Check for spot termination notice
  HTTP_CODE=$(curl -s -o /tmp/spot-action.json -w "%%{http_code}" "$METADATA_ENDPOINT" 2>/dev/null)
  
  if [ "$HTTP_CODE" == "200" ]; then
    echo "[$(date)] Spot termination notice received!" | tee -a "$LOG_FILE"
    cat /tmp/spot-action.json | jq '.' | tee -a "$LOG_FILE"
    
    # Stop agents gracefully
    /usr/local/bin/stop_azdevops_agent.sh 2>&1 | tee -a "$LOG_FILE"
    
    echo "[$(date)] Graceful shutdown complete" | tee -a "$LOG_FILE"
    break
  fi
  
  # Check every 5 seconds
  sleep 5
done
EC2_MONITOR_SCRIPT

chmod +x /usr/local/bin/ec2_monitor.sh

# Create systemd service for agent
echo "Creating systemd service for agent..."
cat > /etc/systemd/system/azdevops-agent.service << 'AGENT_SERVICE'
[Unit]
Description=Azure DevOps Agent
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
Environment="AZP_URL=${azp_url}"
Environment="AZP_TOKEN=${azp_token}"
Environment="AZP_POOL=${azp_pool}"
Environment="AZP_AGENT_NAME=${azp_agent_name}-$(hostname)"
ExecStart=/usr/local/bin/start_azdevops_agent.sh
ExecStop=/usr/local/bin/stop_azdevops_agent.sh

[Install]
WantedBy=multi-user.target
AGENT_SERVICE

# Create systemd service for spot monitor
echo "Creating systemd service for spot monitor..."
cat > /etc/systemd/system/ec2-monitor.service << 'EC2_MONITOR_SERVICE'
[Unit]
Description=EC2 Spot Termination Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ec2_monitor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EC2_MONITOR_SERVICE

# Setup cron for monitoring (backup)
echo "Setting up cron job..."
cat > /etc/cron.d/ec2-monitor << 'CRON_MONITOR'
*/1 * * * * root /usr/local/bin/ec2_monitor.sh >> /var/log/ec2_monitor.log 2>&1
CRON_MONITOR

# Reload systemd
echo "Reloading systemd..."
systemctl daemon-reload

# Start agent
echo "Starting Azure DevOps agent..."
systemctl enable azdevops-agent.service
systemctl start azdevops-agent.service

# Start spot monitor
echo "Starting EC2 spot monitor..."
systemctl enable ec2-monitor.service
systemctl start ec2-monitor.service

# Wait a moment for agent to start
sleep 10

# Verify agent is running
echo "Verifying agent status..."
if systemctl is-active --quiet azdevops-agent.service; then
  echo "✓ Azure DevOps agent service is running"
else
  echo "✗ Azure DevOps agent service failed to start"
  systemctl status azdevops-agent.service
fi

if docker ps | grep -q azdevops-agent; then
  echo "✓ Azure DevOps agent container is running"
  docker ps | grep azdevops-agent
else
  echo "✗ Azure DevOps agent container not found"
  docker ps -a | grep azdevops-agent
fi

# Log completion
echo "========================================="
echo "Azure DevOps Agent initialization complete!"
echo "Completed at: $(date)"
echo "========================================="

# Create completion marker
touch /var/log/agent-init-complete.log
echo "Azure DevOps Agent is ready at $(date)" > /var/log/agent-init-complete.log
