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

# Auto-detect CPU count if runner_count is 0
if [ "$RUNNER_COUNT" = "0" ]; then
  RUNNER_COUNT=$(nproc)
fi

# Limit CPU per runner
CPU_COUNT=$(nproc)
MAX_CPU=$((CPU_COUNT > 1 ? 2 : 1))

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
  
  docker run \
    --privileged \
    --tty \
    --detach \
    --cpus="$${MAX_CPU}" \
    -e GITLAB_URL="$GITLAB_URL" \
    -e GITLAB_TOKEN="$GITLAB_TOKEN" \
    -e RUNNER_NAME="$RUNNER_NAME" \
    -e RUNNER_TAGS="$RUNNER_TAGS" \
    -e RUNNER_EXECUTOR="docker" \
    -e RUNNER_DOCKER_IMAGE="alpine:latest" \
    -e RUNNER_RUN_UNTAGGED="false" \
    -e RUNNER_LOCKED="false" \
    -e RUNNER_ACCESS_LEVEL="not_protected" \
    -v "$CONFIG_DIR":/etc/gitlab-runner \
    -v "$DATA_DIR":/runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --restart unless-stopped \
    --name "$CONTAINER_NAME" \
    "$DOCKER_IMAGE"
  
  echo "  Container $CONTAINER_NAME started successfully"
done

echo "All runners started successfully!"
RUNEOF
chmod +x /opt/run-gitlab-runners.sh

# Wait for Docker to be fully ready
sleep 10

# Start GitLab runners
/opt/run-gitlab-runners.sh >> /var/log/gitlab-runner-init.log 2>&1

echo "GitLab Runner instance initialization complete!"
