#!/bin/bash

# Exit on error
set -e

echo "======================================"
echo "Azure Private Endpoint Deployment"
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if required tools are installed
echo -e "${BLUE}Checking prerequisites...${NC}"
command -v az >/dev/null 2>&1 || { echo -e "${RED}Azure CLI is required but not installed. Aborting.${NC}" >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform is required but not installed. Aborting.${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker is required but not installed. Aborting.${NC}" >&2; exit 1; }

# Check if logged in to Azure
echo -e "${BLUE}Checking Azure authentication...${NC}"
az account show >/dev/null 2>&1 || { echo -e "${RED}Not logged in to Azure. Please run 'az login' first.${NC}" >&2; exit 1; }

echo -e "${GREEN}Prerequisites check passed!${NC}"

# Step 1: Initialize and apply Terraform
echo -e "\n${BLUE}Step 1: Deploying infrastructure with Terraform...${NC}"
cd terraform

if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}terraform.tfvars not found. Please create it from terraform.tfvars.example${NC}"
    exit 1
fi

echo "Initializing Terraform..."
terraform init

echo "Planning Terraform deployment..."
terraform plan -out=tfplan

echo "Applying Terraform configuration..."
terraform apply tfplan

# Get outputs
echo -e "\n${BLUE}Getting Terraform outputs...${NC}"
ACR_NAME=$(terraform output -raw container_registry_name)
ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server)
CONTAINER_APP_URL=$(terraform output -raw container_app_url)

echo -e "${GREEN}Infrastructure deployed successfully!${NC}"
echo "ACR Name: $ACR_NAME"
echo "ACR Login Server: $ACR_LOGIN_SERVER"
echo "Container App URL: $CONTAINER_APP_URL"

cd ..

# Step 2: Build and push Docker image
echo -e "\n${BLUE}Step 2: Building and pushing Docker image...${NC}"
cd app

echo "Logging in to Azure Container Registry..."
az acr login --name $ACR_NAME

echo "Building Docker image..."
docker build -t ${ACR_LOGIN_SERVER}/api-app:latest .

echo "Pushing Docker image..."
docker push ${ACR_LOGIN_SERVER}/api-app:latest

echo -e "${GREEN}Docker image pushed successfully!${NC}"

cd ..

# Step 3: Update Container App with new image
echo -e "\n${BLUE}Step 3: Updating Container App...${NC}"
cd terraform

echo "Triggering Container App revision update..."
terraform apply -auto-approve

echo -e "${GREEN}Container App updated successfully!${NC}"

# Final output
echo -e "\n${GREEN}======================================"
echo "Deployment Complete!"
echo "======================================${NC}"
echo ""
echo "Container App URL: $CONTAINER_APP_URL"
echo ""
echo "Test the endpoints:"
echo "  Health Check:       ${CONTAINER_APP_URL}/"
echo "  Cosmos DB Test:     ${CONTAINER_APP_URL}/test-cosmos"
echo "  Storage Test:       ${CONTAINER_APP_URL}/test-storage"
echo ""
echo -e "${GREEN}======================================"
