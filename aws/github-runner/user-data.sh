#!/bin/bash
set -e

# User data script for GitHub Runner on AWS EC2

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
echo "Stopping GitHub runners..."
RUNNER_CONTAINERS=$(docker ps --filter "name=github-runner-" --format "{{.Names}}" | sort)
if [ -z "$RUNNER_CONTAINERS" ]; then
  echo "No running GitHub runner containers found."
  exit 0
fi
for CONTAINER_NAME in $RUNNER_CONTAINERS; do
  echo "Stopping $CONTAINER_NAME..."
  docker stop -t 30 "$CONTAINER_NAME" > /dev/null 2>&1 || true
  docker rm "$CONTAINER_NAME" > /dev/null 2>&1 || true
  echo "  $CONTAINER_NAME stopped and removed"
done
echo "All GitHub runners stopped successfully!"
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
  echo "Runners shutdown complete. Instance will terminate at: $TERMINATION_TIME"
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

# Create GitHub runner startup script
cat > /opt/run-github-runners.sh << 'RUNEOF'
#!/bin/bash
set -e

GITHUB_URL="${github_url}"
GITHUB_TOKEN="${github_token}"
RUNNER_LABELS="${runner_labels}"
RUNNER_COUNT="${runner_count}"
DOCKER_IMAGE="${runner_docker_image}"

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

echo "Starting $RUNNER_COUNT GitHub runner(s)..."

for R in $(seq 1 $RUNNER_COUNT); do
  RUNNER_NAME="runner-$(hostname)-$R"
  WORK_DIR="/mnt/runner$R/_work"
  CONTAINER_NAME="github-runner-$R"
  
  mkdir -p "$WORK_DIR"
  
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
    -e GITHUB_URL="$GITHUB_URL" \
    -e GITHUB_TOKEN="$GITHUB_TOKEN" \
    -e RUNNER_NAME="$RUNNER_NAME" \
    -e RUNNER_LABELS="$RUNNER_LABELS" \
    -e RUNNER_WORK_DIRECTORY="/_work" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$WORK_DIR":/_work \
    --restart unless-stopped \
    --name "$CONTAINER_NAME" \
    "$DOCKER_IMAGE"
  
  echo "  Container $CONTAINER_NAME started successfully"
done

echo "All runners started successfully!"
RUNEOF
chmod +x /opt/run-github-runners.sh

# Wait for Docker to be fully ready
sleep 10

# Start GitHub runners
/opt/run-github-runners.sh >> /var/log/github-runner-init.log 2>&1

echo "GitHub Runner instance initialization complete!"
