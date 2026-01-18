#!/bin/bash
# =============================================================================
# Self-Hosted Runner Prerequisites Validator
# =============================================================================
# This script checks if you have everything needed to deploy runners
# Run this before attempting deployment
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Self-Hosted Runner - Prerequisites Validator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# =============================================================================
# Check Terraform
# =============================================================================
echo -n "Checking Terraform... "
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
    REQUIRED_VERSION="1.5.0"
    
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$TERRAFORM_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        echo -e "${GREEN}✓${NC} Found v${TERRAFORM_VERSION}"
    else
        echo -e "${RED}✗${NC} Version ${TERRAFORM_VERSION} is too old (need >= ${REQUIRED_VERSION})"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}✗${NC} Not found"
    echo -e "  Install: ${BLUE}brew install terraform${NC} or visit https://terraform.io"
    ERRORS=$((ERRORS + 1))
fi

# =============================================================================
# Check Cloud CLIs
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Cloud Provider CLIs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Azure CLI
echo -n "Checking Azure CLI... "
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --output json | grep -o '"azure-cli": "[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}✓${NC} Found v${AZ_VERSION}"
    
    # Check if logged in
    echo -n "  Checking Azure authentication... "
    if az account show &> /dev/null; then
        SUBSCRIPTION=$(az account show --query name -o tsv)
        echo -e "${GREEN}✓${NC} Logged in (${SUBSCRIPTION})"
    else
        echo -e "${YELLOW}⚠${NC} Not authenticated"
        echo -e "    Run: ${BLUE}az login${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠${NC} Not found (only needed for Azure deployments)"
    echo -e "  Install: ${BLUE}brew install azure-cli${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# AWS CLI
echo -n "Checking AWS CLI... "
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    echo -e "${GREEN}✓${NC} Found v${AWS_VERSION}"
    
    # Check if configured
    echo -n "  Checking AWS credentials... "
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        echo -e "${GREEN}✓${NC} Configured (Account: ${AWS_ACCOUNT})"
    else
        echo -e "${YELLOW}⚠${NC} Not configured"
        echo -e "    Run: ${BLUE}aws configure${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠${NC} Not found (only needed for AWS deployments)"
    echo -e "  Install: ${BLUE}brew install awscli${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# =============================================================================
# Check for terraform.tfvars
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Configuration Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -n "Checking for terraform.tfvars... "
if [ -f "terraform.tfvars" ]; then
    echo -e "${GREEN}✓${NC} Found"
    
    # Validate required variables
    echo "  Validating configuration:"
    
    # Check for common required variables
    for var in "project_name" "gitlab_token" "gitlab_url"; do
        echo -n "    ${var}... "
        if grep -q "^[[:space:]]*${var}[[:space:]]*=" terraform.tfvars 2>/dev/null; then
            VALUE=$(grep "^[[:space:]]*${var}[[:space:]]*=" terraform.tfvars | cut -d'=' -f2 | tr -d ' "' | head -1)
            if [ ! -z "$VALUE" ] && [ "$VALUE" != "xxxxx" ] && [ "$VALUE" != "your-" ]; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC} Not configured (still has example value)"
                ERRORS=$((ERRORS + 1))
            fi
        else
            echo -e "${YELLOW}⚠${NC} Not found (might be in different format)"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
else
    echo -e "${YELLOW}⚠${NC} Not found"
    echo -e "  ${BLUE}TIP:${NC} Copy from examples/ or terraform.tfvars.example"
    echo -e "       ${BLUE}cp ../../examples/minimal/azure-gitlab.tfvars terraform.tfvars${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# =============================================================================
# Check network connectivity
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Network Connectivity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check GitLab connectivity
echo -n "Checking GitLab.com connectivity... "
if curl -s --head --connect-timeout 5 https://gitlab.com > /dev/null; then
    echo -e "${GREEN}✓${NC} Reachable"
else
    echo -e "${YELLOW}⚠${NC} Cannot reach GitLab.com (check firewall/proxy)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check GitHub connectivity
echo -n "Checking GitHub.com connectivity... "
if curl -s --head --connect-timeout 5 https://github.com > /dev/null; then
    echo -e "${GREEN}✓${NC} Reachable"
else
    echo -e "${YELLOW}⚠${NC} Cannot reach GitHub.com (check firewall/proxy)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Docker Hub connectivity
echo -n "Checking Docker Hub connectivity... "
if curl -s --head --connect-timeout 5 https://hub.docker.com > /dev/null; then
    echo -e "${GREEN}✓${NC} Reachable"
else
    echo -e "${YELLOW}⚠${NC} Cannot reach Docker Hub (check firewall/proxy)"
    WARNINGS=$((WARNINGS + 1))
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC} You're ready to deploy."
    echo ""
    echo "Next steps:"
    echo "  1. Review your terraform.tfvars configuration"
    echo "  2. Run: ${BLUE}terraform init${NC}"
    echo "  3. Run: ${BLUE}terraform plan${NC}"
    echo "  4. Run: ${BLUE}terraform apply${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ ${WARNINGS} warning(s) found${NC}"
    echo ""
    echo "You can proceed, but review warnings above."
    echo ""
    echo "Next steps:"
    echo "  1. Address warnings (optional)"
    echo "  2. Run: ${BLUE}terraform init${NC}"
    echo "  3. Run: ${BLUE}terraform plan${NC}"
    echo "  4. Run: ${BLUE}terraform apply${NC}"
    exit 0
else
    echo -e "${RED}✗ ${ERRORS} error(s) found${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ ${WARNINGS} warning(s) found${NC}"
    fi
    echo ""
    echo "Please fix the errors above before proceeding."
    exit 1
fi
