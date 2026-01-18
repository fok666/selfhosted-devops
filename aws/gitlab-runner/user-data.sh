#!/bin/bash
set -e

# User data script for GitLab Runner on AWS EC2

# Update and install packages
apt-get update
apt-get install -y docker.io curl jq

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Create stop script
cat > /opt/stop.sh << 'STOPEOF'
#!/bin/bash
set -e
echo "Stopping GitLab runners..."
RUNNER_CONTAINERS=$(docker ps --filter "name=gitlab-runner-" --format "{{.Names}}" | sort)
if [ -z "$RUNNER_CONTAINERS" ]; then
  echo "No running GitLab runner containers found."
  exit 0
fi
for CONTAINER_NAME in $RUNNER_CONTAINERS; do
  echo "Stopping $CONTAINER_NAME..."
  docker stop -t 30 "$CONTAINER_NAME" > /dev/null 2>&1 || true
  docker rm "$CONTAINER_NAME" > /dev/null 2>&1 || true
  echo "  $CONTAINER_NAME stopped and removed"
done
echo "All GitLab runners stopped successfully!"
STOPEOF
chmod +x /opt/stop.sh

# Create EC2 spot termination monitor script
cat > /opt/ec2_monitor.sh << 'MONEOF'
#!/bin/bash
set -e
METADATA_ENDPOINT='http://169.254.169.254/latest/meta-data/spot/instance-action'
STOP_SCRIPT='/opt/stop.sh'
echo "Checking for EC2 spot instance termination notice..."
RESPONSE=$(curl -s -f "$METADATA_ENDPOINT" 2>/dev/null || echo "")
if [ -n "$RESPONSE" ]; then
  echo "Spot instance termination notice detected!"
  echo "Termination details: $RESPONSE"
  TERMINATION_TIME=$(echo "$RESPONSE" | jq -r '.time' 2>/dev/null || echo "Unknown")
  ACTION=$(echo "$RESPONSE" | jq -r '.action' 2>/dev/null || echo "terminate")
  echo "Action: $ACTION"
  echo "Termination time: $TERMINATION_TIME"
  echo "Initiating graceful shutdown..."
  if [ -x "$STOP_SCRIPT" ]; then
    echo "Executing stop script: $STOP_SCRIPT"
    "$STOP_SCRIPT"
  else
    echo "Warning: Stop script not found or not executable: $STOP_SCRIPT"
  fi
  echo "Agents shutdown complete. Instance will terminate at: $TERMINATION_TIME"
else
  echo "No spot instance termination notice"
fi
MONEOF
chmod +x /opt/ec2_monitor.sh

# Set up EC2 spot termination monitoring (check every 5 seconds)
(crontab -l 2>/dev/null; echo "* * * * * /opt/ec2_monitor.sh >> /var/log/ec2_monitor.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "* * * * * sleep 5; /opt/ec2_monitor.sh >> /var/log/ec2_monitor.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "* * * * * sleep 10; /opt/ec2_monitor.sh >> /var/log/ec2_monitor.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "* * * * * sleep 15; /opt/ec2_monitor.sh >> /var/log/ec2_monitor.log 2>&1") | crontab -

# Create GitLab runner startup script
cat > /opt/run-gitlab-runners.sh << 'RUNEOF'
#!/bin/bash
set -e

GITLAB_URL="${gitlab_url}"
GITLAB_TOKEN="${gitlab_token}"
RUNNER_TAGS="${runner_tags}"
RUNNER_COUNT="${runner_count}"
DOCKER_IMAGE="${runner_docker_image}"

# Production Features Configuration
ENABLE_CACHE="${enable_distributed_cache}"
CACHE_S3_BUCKET="${cache_s3_bucket_name}"
CACHE_S3_REGION="${cache_s3_bucket_region}"
CACHE_SHARED="${cache_shared}"
ENABLE_MONITORING="${enable_runner_monitoring}"
METRICS_PORT="${metrics_port}"

# Auto-detect runner count based on CPU count if runner_count is 0
if [ "$RUNNER_COUNT" = "0" ]; then
  CPU_COUNT=$(nproc)
  # Scale runner count based on available CPUs:
  # 1-2 CPUs: 1 runner
  # 3-4 CPUs: 2 runners
  # 5-8 CPUs: 3 runners
  # 9-16 CPUs: 4 runners
  # 17+ CPUs: CPU_COUNT / 4 (rounded up)
  if [ $CPU_COUNT -le 2 ]; then
    RUNNER_COUNT=1
  elif [ $CPU_COUNT -le 4 ]; then
    RUNNER_COUNT=2
  elif [ $CPU_COUNT -le 8 ]; then
    RUNNER_COUNT=3
  elif [ $CPU_COUNT -le 16 ]; then
    RUNNER_COUNT=4
  else
    RUNNER_COUNT=$(( (CPU_COUNT + 3) / 4 ))
  fi
  echo "Auto-detected $CPU_COUNT CPUs, will run $RUNNER_COUNT runners"
fi

# Calculate CPU limit per runner
CPU_COUNT=$(nproc)
MAX_CPU=$((CPU_COUNT / RUNNER_COUNT))
[ $MAX_CPU -lt 1 ] && MAX_CPU=1

echo "Starting $RUNNER_COUNT GitLab runner(s)..."

for R in $(seq 1 $RUNNER_COUNT); do
  RUNNER_NAME="gitlab-runner-$(hostname)-$R"
  CONFIG_DIR="/mnt/gitlab-runner$R/config"
  DATA_DIR="/mnt/gitlab-runner$R/data"
  CONTAINER_NAME="gitlab-runner-$R"
  
  mkdir -p "$CONFIG_DIR"
  mkdir -p "$DATA_DIR"
  
  echo "Starting runner $R/$RUNNER_COUNT: $RUNNER_NAME"
  
  if docker ps -a --format '{{.Names}}' | grep -q "^$${CONTAINER_NAME}$"; then
    echo "  Removing existing container: $CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true
  fi
  
  # Build docker run command safely using an array
  DOCKER_ARGS=(
    --privileged --tty --detach --cpus="$MAX_CPU"
    -e GITLAB_URL="$GITLAB_URL"
    -e GITLAB_TOKEN="$GITLAB_TOKEN"
    -e RUNNER_NAME="$RUNNER_NAME"
    -e RUNNER_TAGS="$RUNNER_TAGS"
    -e RUNNER_EXECUTOR="docker"
    -e RUNNER_DOCKER_IMAGE="alpine:latest"
    -e RUNNER_RUN_UNTAGGED="false"
    -e RUNNER_LOCKED="false"
    -e RUNNER_ACCESS_LEVEL="not_protected"
  )
  
  # Add monitoring configuration if enabled
  if [ "$ENABLE_MONITORING" = "true" ]; then
    echo "  Enabling Prometheus metrics on port $METRICS_PORT"
    DOCKER_ARGS+=(-p "$METRICS_PORT:$METRICS_PORT")
    DOCKER_ARGS+=(-e "RUNNER_LISTEN_ADDRESS=:$METRICS_PORT")
  fi
  
  DOCKER_ARGS+=(
    -v "$CONFIG_DIR":/etc/gitlab-runner
    -v "$DATA_DIR":/runner
    -v /var/run/docker.sock:/var/run/docker.sock
    --restart unless-stopped
    --name "$CONTAINER_NAME"
    "$DOCKER_IMAGE"
  )
  
  # Execute docker run
  docker run "$${DOCKER_ARGS[@]}"
  
  echo "  Container $CONTAINER_NAME started successfully"
  
  # Configure distributed cache if enabled
  if [ "$ENABLE_CACHE" = "true" ]; then
    echo "  Configuring S3 distributed cache..."
    
    # Wait for config.toml to be created
    sleep 5
    CONFIG_FILE="$CONFIG_DIR/config.toml"
    
    # Determine cache path based on sharing preference
    if [ "$CACHE_SHARED" = "true" ]; then
      CACHE_PATH="gitlab-runner"
      echo "    Using shared cache for all runners"
    else
      CACHE_PATH="gitlab-runner-$R"
      echo "    Using isolated cache for this runner"
    fi
    
    # Use AWS region from variable or default to us-east-1
    CACHE_REGION="$${CACHE_S3_REGION:-us-east-1}"
    
    # Add cache configuration to config.toml
    if [ -f "$CONFIG_FILE" ]; then
      # Backup original config
      cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
      
      # Insert cache configuration before [[runners]] section
      sed -i '/\[\[runners\]\]/i \
  [runners.cache]\n\
    Type = "s3"\n\
    Shared = '"$CACHE_SHARED"'\n\
    [runners.cache.s3]\n\
      ServerAddress = "s3.amazonaws.com"\n\
      BucketName = "'"$CACHE_S3_BUCKET"'"\n\
      BucketLocation = "'"$CACHE_REGION"'"\n\
' "$CONFIG_FILE"
      
      echo "    Cache configured: s3://$CACHE_S3_BUCKET/$CACHE_PATH"
      
      # Restart runner to apply cache configuration
      docker restart "$CONTAINER_NAME" > /dev/null 2>&1
      echo "    Runner restarted with cache configuration"
    else
      echo "    Warning: config.toml not found, cache configuration skipped"
    fi
  fi
done

echo "All runners started successfully!"
RUNEOF
chmod +x /opt/run-gitlab-runners.sh

# Wait for Docker to be fully ready
sleep 10

# Configure CloudWatch Logs if enabled
# shellcheck disable=SC2154  # enable_centralized_logging is injected by Terraform templatefile()
ENABLE_LOGGING="${enable_centralized_logging}"
if [ "$ENABLE_LOGGING" = "true" ]; then
  echo "Configuring CloudWatch Logs..."
  
  # Install CloudWatch agent
  wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
  dpkg -i -E ./amazon-cloudwatch-agent.deb
  rm amazon-cloudwatch-agent.deb
  
  # Create CloudWatch agent configuration
  cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/gitlab-runner-init.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/init",
            "retention_in_days": ${log_retention_days}
          },
          {
            "file_path": "/var/log/ec2_monitor.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/monitor",
            "retention_in_days": ${log_retention_days}
          }
        ]
      }
    }
  }
}
CWEOF
  
  # Start CloudWatch agent
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
  
  echo "CloudWatch Logs configured successfully"
fi

# Start GitLab runners
/opt/run-gitlab-runners.sh >> /var/log/gitlab-runner-init.log 2>&1

echo "GitLab Runner instance initialization complete!"
