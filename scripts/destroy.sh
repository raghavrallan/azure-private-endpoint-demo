#!/bin/bash

# Exit on error
set -e

echo "======================================"
echo "Azure Private Endpoint Cleanup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${RED}WARNING: This will destroy all resources created by Terraform!${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

cd terraform

echo -e "\n${BLUE}Destroying infrastructure...${NC}"
terraform destroy -auto-approve

echo -e "\n${GREEN}All resources destroyed successfully!${NC}"
