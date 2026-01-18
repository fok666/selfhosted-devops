#!/bin/bash
# =============================================================================
# Self-Hosted Runner Quick Deploy Script
# =============================================================================
# Interactive deployment script for first-time users
# Simplifies the deployment process with guided prompts
# =============================================================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${BOLD}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result
    
    echo -ne "${CYAN}?${NC} ${prompt} ${YELLOW}[${default}]${NC}: "
    read result
    echo "${result:-$default}"
}

# =============================================================================
# Main Script
# =============================================================================

clear
print_header "Self-Hosted Runner - Quick Deploy 🚀"

echo "This script will guide you through deploying a self-hosted CI/CD runner."
echo ""
echo -e "${BOLD}What this script does:${NC}"
echo "  1. Helps you choose the right configuration"
echo "  2. Collects required information"
echo "  3. Creates terraform.tfvars from a preset"
echo "  4. Validates prerequisites"
echo "  5. Deploys the infrastructure"
echo ""
echo -n "Ready to get started? (y/n): "
read START
if [ "$START" != "y" ] && [ "$START" != "Y" ]; then
    echo "Exiting..."
    exit 0
fi

# =============================================================================
# Step 1: Choose Cloud Provider
# =============================================================================

print_header "Step 1: Choose Cloud Provider"

echo "Which cloud provider do you want to use?"
echo ""
echo "  1) Azure"
echo "  2) AWS"
echo ""
CLOUD=$(prompt_with_default "Choose" "1")

case $CLOUD in
    1|azure|Azure)
        CLOUD_NAME="azure"
        ;;
    2|aws|AWS)
        CLOUD_NAME="aws"
        ;;
    *)
        print_error "Invalid choice. Exiting."
        exit 1
        ;;
esac

print_success "Selected: $CLOUD_NAME"

# =============================================================================
# Step 2: Choose CI/CD Platform
# =============================================================================

print_header "Step 2: Choose CI/CD Platform"

echo "Which CI/CD platform are you using?"
echo ""
echo "  1) GitLab Runner"
echo "  2) GitHub Actions"
echo "  3) Azure DevOps Agent"
echo ""
PLATFORM=$(prompt_with_default "Choose" "1")

case $PLATFORM in
    1|gitlab|GitLab)
        PLATFORM_NAME="gitlab-runner"
        PLATFORM_DISPLAY="GitLab Runner"
        ;;
    2|github|GitHub)
        PLATFORM_NAME="github-runner"
        PLATFORM_DISPLAY="GitHub Actions"
        ;;
    3|azure-devops|azdo)
        PLATFORM_NAME="azure-devops-agent"
        PLATFORM_DISPLAY="Azure DevOps Agent"
        ;;
    *)
        print_error "Invalid choice. Exiting."
        exit 1
        ;;
esac

print_success "Selected: $PLATFORM_DISPLAY"

DEPLOYMENT_DIR="${CLOUD_NAME}/${PLATFORM_NAME}"

# =============================================================================
# Step 3: Choose Configuration Preset
# =============================================================================

print_header "Step 3: Choose Configuration Preset"

echo "Which configuration matches your needs?"
echo ""
echo -e "  1) ${BOLD}Minimal${NC} - Learning/testing, minimum cost (~$5-20/mo)"
echo "     • Scale to zero when idle"
echo "     • Small VMs, spot instances only"
echo "     • Best for: Testing, individual developers"
echo ""
echo -e "  2) ${BOLD}Development${NC} - Dev/test environments (~$40-80/mo)"
echo "     • Maintains 1 baseline instance"
echo "     • Good for small teams (5-10 developers)"
echo "     • Best for: Development pipelines"
echo ""
echo -e "  3) ${BOLD}Production${NC} - Production workloads (~$150-300/mo)"
echo "     • Maintains 2-3 baseline instances"
echo "     • High availability, fast response"
echo "     • Best for: Business-critical CI/CD"
echo ""
echo -e "  4) ${BOLD}High-Performance${NC} - Enterprise workloads (~$500-1000/mo)"
echo "     • Large VMs, premium storage"
echo "     • Maximum capacity and speed"
echo "     • Best for: Large teams, heavy workloads"
echo ""

CONFIG=$(prompt_with_default "Choose" "2")

case $CONFIG in
    1|minimal|Minimal)
        CONFIG_NAME="minimal"
        CONFIG_DISPLAY="Minimal"
        ;;
    2|dev|development|Development)
        CONFIG_NAME="development"
        CONFIG_DISPLAY="Development"
        ;;
    3|prod|production|Production)
        CONFIG_NAME="production"
        CONFIG_DISPLAY="Production"
        ;;
    4|high|high-performance|High-Performance)
        CONFIG_NAME="high-performance"
        CONFIG_DISPLAY="High-Performance"
        ;;
    *)
        print_error "Invalid choice. Exiting."
        exit 1
        ;;
esac

print_success "Selected: $CONFIG_DISPLAY configuration"

# =============================================================================
# Step 4: Collect Required Information
# =============================================================================

print_header "Step 4: Configuration"

print_info "Please provide the following information:"
echo ""

PROJECT_NAME=$(prompt_with_default "Project name" "my-runner")
print_success "Project: $PROJECT_NAME"

if [ "$PLATFORM_NAME" = "gitlab-runner" ]; then
    PLATFORM_URL=$(prompt_with_default "GitLab URL" "https://gitlab.com")
    print_success "GitLab URL: $PLATFORM_URL"
    
    echo ""
    print_info "GitLab Runner Token:"
    echo "  Get your token from: GitLab → Settings → CI/CD → Runners"
    echo "  Token format: glrt-xxxxx"
    PLATFORM_TOKEN=$(prompt_with_default "Token" "")
    
    if [[ ! $PLATFORM_TOKEN =~ ^glrt- ]]; then
        print_warning "Token doesn't start with 'glrt-'. Are you sure it's correct?"
    fi
elif [ "$PLATFORM_NAME" = "github-runner" ]; then
    PLATFORM_URL=$(prompt_with_default "GitHub URL" "https://github.com")
    print_success "GitHub URL: $PLATFORM_URL"
    
    echo ""
    print_info "GitHub Personal Access Token (PAT):"
    echo "  Create token at: GitHub → Settings → Developer settings → PAT"
    echo "  Required scope: repo"
    PLATFORM_TOKEN=$(prompt_with_default "Token" "")
else
    PLATFORM_URL=$(prompt_with_default "Azure DevOps URL" "https://dev.azure.com/yourorg")
    print_success "Azure DevOps URL: $PLATFORM_URL"
    
    echo ""
    print_info "Azure DevOps Personal Access Token (PAT):"
    echo "  Create token at: Azure DevOps → User Settings → PAT"
    echo "  Required scope: Agent Pools (Read & Manage)"
    PLATFORM_TOKEN=$(prompt_with_default "Token" "")
fi

if [ "$CLOUD_NAME" = "azure" ]; then
    LOCATION=$(prompt_with_default "Azure region" "East US")
    print_success "Region: $LOCATION"
else
    REGION=$(prompt_with_default "AWS region" "us-east-1")
    print_success "Region: $REGION"
fi

# =============================================================================
# Step 5: Create Configuration File
# =============================================================================

print_header "Step 5: Creating Configuration"

# Navigate to deployment directory
cd "$DEPLOYMENT_DIR" || {
    print_error "Deployment directory not found: $DEPLOYMENT_DIR"
    exit 1
}

# Copy preset configuration
PRESET_FILE="../../examples/${CONFIG_NAME}/${CLOUD_NAME}-gitlab.tfvars"

if [ ! -f "$PRESET_FILE" ]; then
    # Fallback to example file
    print_warning "Preset not found, using terraform.tfvars.example"
    PRESET_FILE="terraform.tfvars.example"
fi

cp "$PRESET_FILE" terraform.tfvars
print_success "Created terraform.tfvars from $CONFIG_DISPLAY preset"

# Update configuration with user values
print_info "Updating configuration with your values..."

# Use sed to replace values (macOS compatible)
if [ "$CLOUD_NAME" = "azure" ]; then
    sed -i '' "s/^project_name.*$/project_name = \"$PROJECT_NAME\"/" terraform.tfvars
    sed -i '' "s/^location.*$/location = \"$LOCATION\"/" terraform.tfvars
else
    sed -i '' "s/^project_name.*$/project_name = \"$PROJECT_NAME\"/" terraform.tfvars
    sed -i '' "s/^region.*$/region = \"$REGION\"/" terraform.tfvars
fi

if [ "$PLATFORM_NAME" = "gitlab-runner" ]; then
    sed -i '' "s|^gitlab_url.*$|gitlab_url = \"$PLATFORM_URL\"|" terraform.tfvars
    sed -i '' "s|^gitlab_token.*$|gitlab_token = \"$PLATFORM_TOKEN\"|" terraform.tfvars
fi

print_success "Configuration updated"

# =============================================================================
# Step 6: Validate Prerequisites
# =============================================================================

print_header "Step 6: Validating Prerequisites"

if [ -f "../../scripts/validate-prerequisites.sh" ]; then
    bash ../../scripts/validate-prerequisites.sh
    VALIDATION_RESULT=$?
    
    if [ $VALIDATION_RESULT -ne 0 ]; then
        echo ""
        print_error "Prerequisites validation failed. Please fix issues and run again."
        exit 1
    fi
else
    print_warning "Prerequisites validator not found, skipping validation"
fi

# =============================================================================
# Step 7: Deploy
# =============================================================================

print_header "Step 7: Deploy Infrastructure"

echo "Ready to deploy with the following configuration:"
echo ""
echo "  Cloud Provider: $CLOUD_NAME"
echo "  Platform:       $PLATFORM_DISPLAY"
echo "  Configuration:  $CONFIG_DISPLAY"
echo "  Project:        $PROJECT_NAME"
echo ""
echo -e "${YELLOW}This will create real cloud resources and incur costs.${NC}"
echo ""
echo -n "Proceed with deployment? (y/n): "
read DEPLOY

if [ "$DEPLOY" != "y" ] && [ "$DEPLOY" != "Y" ]; then
    print_info "Deployment cancelled. Your terraform.tfvars is ready when you are."
    echo ""
    echo "To deploy later, run:"
    echo "  cd $DEPLOYMENT_DIR"
    echo "  terraform init"
    echo "  terraform plan"
    echo "  terraform apply"
    exit 0
fi

# Initialize Terraform
print_info "Initializing Terraform..."
terraform init

# Plan
print_info "Planning deployment..."
terraform plan -out=tfplan

# Apply
print_info "Applying configuration..."
terraform apply tfplan

# =============================================================================
# Success!
# =============================================================================

print_header "Deployment Complete! 🎉"

echo "Your self-hosted runner infrastructure has been deployed!"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo ""
echo "  1. Check runner registration:"
if [ "$PLATFORM_NAME" = "gitlab-runner" ]; then
    echo "     GitLab → Settings → CI/CD → Runners"
elif [ "$PLATFORM_NAME" = "github-runner" ]; then
    echo "     GitHub → Settings → Actions → Runners"
else
    echo "     Azure DevOps → Project Settings → Agent Pools"
fi
echo ""
echo "  2. Monitor resources in cloud console:"
if [ "$CLOUD_NAME" = "azure" ]; then
    echo "     Azure Portal → Resource Groups → ${PROJECT_NAME}-rg"
else
    echo "     AWS Console → EC2 → Auto Scaling Groups"
fi
echo ""
echo "  3. Test with a simple CI/CD job"
echo ""
echo -e "  4. Monitor costs:"
if [ "$CLOUD_NAME" = "azure" ]; then
    echo "     Azure Portal → Cost Management"
else
    echo "     AWS Console → Cost Explorer"
fi
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "  • QUICKSTART.md - Detailed guide"
echo "  • SECURITY.md - Security best practices"
echo "  • ARCHITECTURE.md - Architecture details"
echo ""
echo -e "${GREEN}Happy building! 🚀${NC}"
