#!/bin/bash
# run-tests.sh - Quick test runner for Terraform configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Terraform Test Runner${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to run tests for a directory
run_tests() {
    local dir=$1
    local name=$2
    
    if [ ! -d "$dir" ]; then
        echo -e "${YELLOW}⚠️  Directory not found: $dir${NC}"
        return 0
    fi
    
    if [ ! -d "$dir/tests" ]; then
        echo -e "${YELLOW}⚠️  No tests directory in: $dir${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Testing: $name${NC}"
    echo "Location: $dir"
    echo ""
    
    cd "$dir"
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        echo "Initializing..."
        terraform init -backend=false > /dev/null 2>&1
    fi
    
    # Run tests
    if terraform test -verbose; then
        echo -e "${GREEN}✅ Tests passed: $name${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}❌ Tests failed: $name${NC}"
        echo ""
        return 1
    fi
    
    cd - > /dev/null
}

# Track results
failed_tests=()
passed_tests=()

# Test modules
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}MODULE TESTS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if run_tests "modules/aws-asg" "AWS ASG Module"; then
    passed_tests+=("AWS ASG Module")
else
    failed_tests+=("AWS ASG Module")
fi

if run_tests "modules/azure-vmss" "Azure VMSS Module"; then
    passed_tests+=("Azure VMSS Module")
else
    failed_tests+=("Azure VMSS Module")
fi

# Test AWS configurations
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}AWS INTEGRATION TESTS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if run_tests "aws/gitlab-runner" "AWS GitLab Runner"; then
    passed_tests+=("AWS GitLab Runner")
else
    failed_tests+=("AWS GitLab Runner")
fi

if run_tests "aws/github-runner" "AWS GitHub Runner"; then
    passed_tests+=("AWS GitHub Runner")
else
    failed_tests+=("AWS GitHub Runner")
fi

if run_tests "aws/azure-devops-agent" "AWS Azure DevOps Agent"; then
    passed_tests+=("AWS Azure DevOps Agent")
else
    failed_tests+=("AWS Azure DevOps Agent")
fi

# Test Azure configurations
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}AZURE INTEGRATION TESTS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if run_tests "azure/gitlab-runner" "Azure GitLab Runner"; then
    passed_tests+=("Azure GitLab Runner")
else
    failed_tests+=("Azure GitLab Runner")
fi

if run_tests "azure/github-runner" "Azure GitHub Runner"; then
    passed_tests+=("Azure GitHub Runner")
else
    failed_tests+=("Azure GitHub Runner")
fi

if run_tests "azure/azure-devops-agent" "Azure Azure DevOps Agent"; then
    passed_tests+=("Azure Azure DevOps Agent")
else
    failed_tests+=("Azure Azure DevOps Agent")
fi

# Summary
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  TEST SUMMARY${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

echo -e "${GREEN}Passed: ${#passed_tests[@]}${NC}"
for test in "${passed_tests[@]}"; do
    echo -e "  ${GREEN}✅ $test${NC}"
done
echo ""

if [ ${#failed_tests[@]} -gt 0 ]; then
    echo -e "${RED}Failed: ${#failed_tests[@]}${NC}"
    for test in "${failed_tests[@]}"; do
        echo -e "  ${RED}❌ $test${NC}"
    done
    echo ""
    exit 1
else
    echo -e "${GREEN}All tests passed! 🎉${NC}"
    echo ""
    exit 0
fi
