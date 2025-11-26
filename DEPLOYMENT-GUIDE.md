# Azure Private Endpoint Infrastructure - Complete Deployment Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Project Structure](#project-structure)
4. [What Gets Deployed](#what-gets-deployed)
5. [Step-by-Step Deployment](#step-by-step-deployment)
6. [Verification & Testing](#verification--testing)
7. [Private Endpoint Validation](#private-endpoint-validation)
8. [API Endpoints](#api-endpoints)
9. [Troubleshooting](#troubleshooting)
10. [Cleanup](#cleanup)
11. [Cost Estimation](#cost-estimation)

---

## Architecture Overview

This project demonstrates a complete Azure infrastructure setup with **TRUE private endpoint connectivity** for secure communication between services within a Virtual Network.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Virtual Network (10.0.0.0/16)                     │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │    Container App Subnet (10.0.2.0/23)                          │ │
│  │    - VNet Integrated                                           │ │
│  │                                                                 │ │
│  │    ┌──────────────────────────────────────────────────────┐   │ │
│  │    │  Container App Environment                           │   │ │
│  │    │                                                       │   │ │
│  │    │  ┌────────────────────────────────────────────┐     │   │ │
│  │    │  │  Python Flask API Container                │     │   │ │
│  │    │  │  - Health Check Endpoint                   │     │   │ │
│  │    │  │  - Cosmos DB Test Endpoint                 │     │   │ │
│  │    │  │  - Storage Test Endpoint                   │     │   │ │
│  │    │  └────────────────────────────────────────────┘     │   │ │
│  │    └──────────────────────────────────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │    Private Endpoint Subnet (10.0.1.0/24)                      │ │
│  │                                                                 │ │
│  │    ┌──────────────────┐         ┌──────────────────┐         │ │
│  │    │ Private Endpoint │         │ Private Endpoint │         │ │
│  │    │   (Cosmos DB)    │         │   (Storage)      │         │ │
│  │    │  10.0.1.4        │         │  10.0.1.5        │         │ │
│  │    └──────────────────┘         └──────────────────┘         │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                            ▲                      ▲                  │
│                            │                      │                  │
│  Private DNS Zones:        │                      │                  │
│  ┌─────────────────────────┴──────────────────────┴────────────────┐│
│  │ privatelink.documents.azure.com                                 ││
│  │ privatelink.blob.core.windows.net                               ││
│  │ (DNS Resolution: service names → private IPs)                   ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
                             │                      │
                    Private  │                      │  Private
                    Traffic  │                      │  Traffic
                             ▼                      ▼
                    ┌────────────────┐    ┌────────────────┐
                    │   Cosmos DB    │    │ Storage Account│
                    │ (Public Access │    │  (Firewall:    │
                    │   DISABLED)    │    │  Default Deny) │
                    └────────────────┘    └────────────────┘

External Resources:
┌───────────────────────────┐
│ Azure Container Registry  │  (Stores Docker images)
│ acrpldev2024001.azurecr.io│
└───────────────────────────┘
```

### Key Security Features

✅ **TRUE Private Connectivity**
- **Cosmos DB**: Public access **COMPLETELY DISABLED** ← Only accessible via Private Endpoint
- **Storage Account**: Firewall enabled with **Default Deny** + Whitelisted IPs only
  - Private endpoint active for VNet access
  - Container App IP whitelisted (app functionality)
  - Your IP whitelisted (portal/CLI access)
  - All other public access blocked
- **Container App**: Runs in VNet-integrated subnet
- All backend traffic stays within Azure backbone

✅ **Network Isolation**
- Separate subnets for private endpoints and workloads
- Private DNS zones for name resolution to private IPs
- No public IPs for backend services
- Firewall rules enforce IP-based access control

---

## Prerequisites

### Required Tools
1. **Azure CLI** (version 2.30.0 or higher)
   ```bash
   az --version
   ```
   Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

2. **Terraform** (version 1.0 or higher)
   ```bash
   terraform --version
   ```
   Install: https://www.terraform.io/downloads

3. **Docker** (for building the application image)
   ```bash
   docker --version
   ```
   Install: https://docs.docker.com/get-docker/

### Azure Requirements
- Active Azure subscription
- Sufficient permissions to create resources
- No resource name conflicts (names must be globally unique)

---

## Project Structure

```
tf-private-endpoint/
├── terraform/
│   ├── main.tf                    # Main configuration, resource groups
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── terraform.tfvars           # Your specific values (generated)
│   ├── terraform.tfvars.example   # Example configuration
│   └── modules/
│       ├── networking/
│       │   ├── main.tf            # VNet, subnets, DNS zones
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── cosmos-db/
│       │   ├── main.tf            # Cosmos DB + private endpoint
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── storage-account/
│       │   ├── main.tf            # Storage + private endpoint
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── container-registry/
│       │   ├── main.tf            # Azure Container Registry
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── container-app/
│           ├── main.tf            # Container App + Environment
│           ├── variables.tf
│           └── outputs.tf
├── app/
│   ├── main.py                    # Python Flask API
│   ├── requirements.txt           # Python dependencies
│   ├── Dockerfile                 # Container definition
│   └── .dockerignore
├── scripts/
│   ├── deploy.sh                  # Linux/Mac deployment
│   ├── deploy.ps1                 # Windows deployment
│   ├── destroy.sh                 # Cleanup script
│   └── destroy.ps1
├── README.md                      # Quick start guide
└── DEPLOYMENT-GUIDE.md           # This file
```

---

## What Gets Deployed

### Resource Groups (5 Total)
| Resource Group | Purpose | Resources |
|---|---|---|
| `rg-privatelink-networking-dev` | Networking | VNet, Subnets, DNS Zones |
| `rg-privatelink-cosmos-dev` | Database | Cosmos DB, Private Endpoint |
| `rg-privatelink-storage-dev` | Storage | Storage Account, Private Endpoint |
| `rg-privatelink-acr-dev` | Registry | Container Registry |
| `rg-privatelink-app-dev` | Application | Container App, Environment, Logs |

### Networking Resources
- **Virtual Network**: `10.0.0.0/16`
- **Subnets**:
  - Private Endpoints: `10.0.1.0/24`
  - Container Apps: `10.0.2.0/23` (delegated to Microsoft.App/environments)
- **Private DNS Zones**:
  - `privatelink.documents.azure.com` (Cosmos DB)
  - `privatelink.blob.core.windows.net` (Storage Account)

### Database Resources
- **Cosmos DB Account**: NoSQL database
  - Database: `testdb`
  - Container: `testcontainer`
  - Partition Key: `/id`
  - Throughput: 400 RU/s
  - **Public Access**: DISABLED ✅

### Storage Resources
- **Storage Account**: Standard LRS
  - Container: `testcontainer`
  - Account Kind: StorageV2
  - **Firewall**: Default Deny with IP Whitelist ✅
  - **Private Endpoint**: Enabled for VNet access ✅

### Container Resources
- **Azure Container Registry**: Premium SKU (required for private endpoints)
- **Container App Environment**: VNet-integrated
- **Container App**: Python Flask API
  - CPU: 0.25 cores
  - Memory: 0.5 GB
  - Replicas: 1-3 (auto-scale)

---

## Step-by-Step Deployment

### Step 1: Login to Azure

```bash
# Login to your Azure account
az login

# List your subscriptions
az account list --output table

# Set the subscription you want to use
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify current subscription
az account show
```

### Step 2: Configure Variables

Navigate to the terraform directory and create your configuration:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your unique values:

```hcl
# Azure Configuration
location     = "eastus"              # Change to your preferred region
environment  = "dev"
project_name = "privatelink"

# IMPORTANT: These names must be globally unique!
# Change the numbers or add your initials

cosmos_db_name          = "cosmos-pl-dev-2024"      # Alphanumeric and hyphens
storage_account_name    = "stpldev2024001"          # Lowercase alphanumeric only, no hyphens
container_registry_name = "acrpldev2024001"         # Alphanumeric only, no hyphens

# Container App Configuration
container_app_name = "api-app"
docker_image_tag   = "latest"
```

### Step 3: Initialize Terraform

```bash
# Initialize Terraform (downloads providers and modules)
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 4: Review the Deployment Plan

```bash
# Create an execution plan
terraform plan
```

This shows you exactly what will be created (should show ~22 resources to add).

### Step 5: Deploy Infrastructure

```bash
# Apply the configuration (will prompt for confirmation)
terraform apply

# OR apply without confirmation
terraform apply -auto-approve
```

**Expected Time**: 10-15 minutes
- Resource groups: ~20 seconds
- VNet and subnets: ~30 seconds
- Cosmos DB: ~2 minutes
- Storage Account: ~1 minute
- Container Registry: ~30 seconds
- Private Endpoints: ~3-8 minutes each
- Container App Environment: ~8-10 minutes

**Note**: The Container App will fail initially because the Docker image doesn't exist yet. This is expected!

### Step 6: Build and Push Docker Image

```bash
# Navigate to app directory
cd ../app

# Login to Azure Container Registry
ACR_NAME=$(cd ../terraform && terraform output -raw container_registry_name)
az acr login --name $ACR_NAME

# Build the Docker image
ACR_SERVER=$(cd ../terraform && terraform output -raw container_registry_login_server)
docker build -t ${ACR_SERVER}/api-app:latest .

# Push to registry
docker push ${ACR_SERVER}/api-app:latest
```

### Step 7: Deploy Container App

```bash
# Return to terraform directory
cd ../terraform

# Apply again to create the Container App
terraform apply -auto-approve
```

This will create the Container App now that the image exists.

### Step 8: Configure Security Settings

```bash
# Get resource names
COSMOS_NAME=$(terraform output -raw cosmos_db_endpoint | cut -d'/' -f3 | cut -d'.' -f1)
STORAGE_NAME=$(terraform output -raw storage_account_name)

# Disable Cosmos DB public access (completely blocks public access)
az cosmosdb update \
  --name $COSMOS_NAME \
  --resource-group rg-privatelink-cosmos-dev \
  --public-network-access Disabled

# Configure Storage Account with firewall (allows specific IPs only)
# Get Container App outbound IP
CONTAINER_APP_IP=$(az containerapp show \
  --name api-app \
  --resource-group rg-privatelink-app-dev \
  --query "properties.outboundIpAddresses[0]" -o tsv)

# Get your current public IP
YOUR_IP=$(curl -4 -s ifconfig.me)

# Enable public access with firewall rules (default deny)
az storage account update \
  --name $STORAGE_NAME \
  --resource-group rg-privatelink-storage-dev \
  --public-network-access Enabled \
  --default-action Deny

# Add Container App IP to firewall
az storage account network-rule add \
  --account-name $STORAGE_NAME \
  --resource-group rg-privatelink-storage-dev \
  --ip-address $CONTAINER_APP_IP

# Add your IP to access from Azure Portal/locally
az storage account network-rule add \
  --account-name $STORAGE_NAME \
  --resource-group rg-privatelink-storage-dev \
  --ip-address $YOUR_IP
```

**IMPORTANT Security Configuration**:
- **Cosmos DB**: Public access completely disabled - ONLY accessible via private endpoint
- **Storage Account**: Firewall enabled with default deny - Only whitelisted IPs can access
  - Container App IP is whitelisted (allows app to function)
  - Your IP is whitelisted (allows portal/local access)
  - Private endpoint is active for VNet-based access

### Step 9: Get the Application URL

```bash
terraform output container_app_url
```

Example output:
```
https://api-app.calmplant-11163936.eastus.azurecontainerapps.io
```

---

## Verification & Testing

### Test Endpoints

Once deployed, test all endpoints:

```bash
# Get the app URL
APP_URL=$(cd terraform && terraform output -raw container_app_url)

# Test health check
curl $APP_URL/

# Test Cosmos DB private endpoint
curl $APP_URL/test-cosmos

# Test Storage Account private endpoint
curl $APP_URL/test-storage
```

### Expected Responses

**Health Check** (`/`):
```json
{
  "status": "healthy",
  "message": "API is running",
  "endpoints": ["/", "/health", "/test-cosmos", "/test-storage"]
}
```

**Cosmos DB Test** (`/test-cosmos`):
```json
{
  "status": "success",
  "message": "Cosmos DB connection via private endpoint is working!",
  "private_endpoint_working": true,
  "database": "testdb",
  "container": "testcontainer",
  "endpoint": "https://cosmos-pl-dev-2024.documents.azure.com:443/",
  "test_item_created": true,
  "total_items": 1
}
```

**Storage Test** (`/test-storage`):
```json
{
  "status": "success",
  "message": "Storage Account connection via private endpoint is working!",
  "private_endpoint_working": true,
  "storage_account": "stpldev2024001",
  "container": "testcontainer",
  "test_blob_uploaded": true,
  "total_blobs": 1
}
```

---

## Private Endpoint Validation

### How to Verify Private Connectivity

#### 1. Check Public Access Status

```bash
# Check Cosmos DB
az cosmosdb show \
  --name cosmos-pl-dev-2024 \
  --resource-group rg-privatelink-cosmos-dev \
  --query "publicNetworkAccess"

# Should return: "Disabled"

# Check Storage Account
az storage account show \
  --name stpldev2024001 \
  --resource-group rg-privatelink-storage-dev \
  --query "{publicAccess: publicNetworkAccess, defaultAction: networkRuleSet.defaultAction, ipRules: networkRuleSet.ipRules}"

# Should return:
# publicAccess: "Enabled"
# defaultAction: "Deny"
# ipRules: [array of allowed IPs]
```

#### 2. Check Private Endpoint Connections

```bash
# Cosmos DB private endpoint status
az cosmosdb show \
  --name cosmos-pl-dev-2024 \
  --resource-group rg-privatelink-cosmos-dev \
  --query "privateEndpointConnections[].privateLinkServiceConnectionState.status"

# Should return: ["Approved"]

# Storage private endpoint status
az storage account show \
  --name stpldev2024001 \
  --resource-group rg-privatelink-storage-dev \
  --query "privateEndpointConnections[].privateLinkServiceConnectionState.status"

# Should return: ["Approved"]
```

#### 3. Test from Outside the VNet

Try to access Cosmos DB from your local machine (outside the VNet):

```bash
# Cosmos DB: This should FAIL because public access is completely disabled
az cosmosdb sql database show \
  --account-name cosmos-pl-dev-2024 \
  --name testdb \
  --resource-group rg-privatelink-cosmos-dev

# Error: "ForbiddenError" - This proves public access is blocked!
```

**Note**: Storage Account access from outside the VNet depends on IP whitelisting. If your IP is added to the firewall rules (Step 8), you'll have access. Otherwise, access will be denied by the firewall.

#### 4. Verify DNS Resolution

```bash
# Check private DNS zone records
az network private-dns record-set a list \
  --resource-group rg-privatelink-networking-dev \
  --zone-name privatelink.documents.azure.com

az network private-dns record-set a list \
  --resource-group rg-privatelink-networking-dev \
  --zone-name privatelink.blob.core.windows.net
```

#### 5. Check Container App Logs

```bash
# View Container App logs to see private IP addresses being used
az containerapp logs show \
  --name api-app \
  --resource-group rg-privatelink-app-dev \
  --follow
```

---

## API Endpoints

### GET /
Health check endpoint to verify the API is running.

**Response**:
```json
{
  "status": "healthy",
  "message": "API is running",
  "endpoints": ["/", "/health", "/test-cosmos", "/test-storage"]
}
```

### GET /health
Detailed health check showing configuration status.

**Response**:
```json
{
  "status": "healthy",
  "configuration": {
    "cosmos_endpoint": "configured",
    "cosmos_key": "configured",
    "storage_connection": "configured",
    "storage_account_name": "stpldev2024001"
  }
}
```

### GET /test-cosmos
Tests Cosmos DB connectivity via private endpoint.

**What it does**:
1. Connects to Cosmos DB using private endpoint
2. Creates a test document in `testdb/testcontainer`
3. Reads the document back
4. Returns connection status

**Response**:
```json
{
  "status": "success",
  "message": "Cosmos DB connection via private endpoint is working!",
  "private_endpoint_working": true,
  "database": "testdb",
  "container": "testcontainer",
  "endpoint": "https://cosmos-pl-dev-2024.documents.azure.com:443/",
  "test_item_created": true,
  "total_items": 1
}
```

### GET /test-storage
Tests Storage Account connectivity via private endpoint.

**What it does**:
1. Connects to Storage Account using private endpoint
2. Uploads a test blob to `testcontainer`
3. Reads the blob back
4. Returns connection status

**Response**:
```json
{
  "status": "success",
  "message": "Storage Account connection via private endpoint is working!",
  "private_endpoint_working": true,
  "storage_account": "stpldev2024001",
  "container": "testcontainer",
  "test_blob_uploaded": true,
  "test_blob_content": "Testing private endpoint connection to Azure Storage",
  "total_blobs": 1
}
```

---

## Troubleshooting

### Issue 1: Terraform Names Already Exist

**Error**: `A resource with the name "xxx" already exists`

**Solution**: Resource names must be globally unique. Update `terraform.tfvars`:
```hcl
cosmos_db_name          = "cosmos-pl-yourname-2024"
storage_account_name    = "stplyourname2024"
container_registry_name = "acrplyourname2024"
```

### Issue 2: Container App Fails to Pull Image

**Error**: `MANIFEST_UNKNOWN: manifest tagged by "latest" is not found`

**Solution**: Build and push the Docker image first (Step 6), then run terraform apply again.

### Issue 3: Cosmos DB/Storage Connection Fails

**Error**: API returns error when testing endpoints

**Solution**:
1. Check if private endpoints are approved:
   ```bash
   az cosmosdb show --name COSMOS_NAME --resource-group rg-privatelink-cosmos-dev \
     --query "privateEndpointConnections[].privateLinkServiceConnectionState.status"
   ```
2. Verify DNS zones are linked to VNet
3. Check Container App logs for detailed errors

### Issue 4: Configure Security Settings

**Problem**: You want to ensure secure access with private endpoints

**Solution**: Run Step 8 to configure security:
```bash
# Cosmos DB: Disable public access completely
az cosmosdb update --name COSMOS_NAME --resource-group rg-privatelink-cosmos-dev --public-network-access Disabled

# Storage Account: Enable firewall with IP whitelist
az storage account update --name STORAGE_NAME --resource-group rg-privatelink-storage-dev --public-network-access Enabled --default-action Deny

# Add Container App IP and your IP to storage firewall (see Step 8 for details)
```

### Issue 5: 403 Forbidden When Accessing Storage Containers

**Problem**: Getting "403 Forbidden" or "Authorization failed" when trying to access storage containers from Azure Portal or CLI.

**Solution**: Your IP address needs to be added to the storage account firewall rules.

```bash
# Get your current public IP
curl -4 ifconfig.me

# Add your IP to storage firewall
az storage account network-rule add \
  --account-name STORAGE_NAME \
  --resource-group rg-privatelink-storage-dev \
  --ip-address YOUR_IP_ADDRESS

# Verify the rule was added
az storage account show \
  --name STORAGE_NAME \
  --resource-group rg-privatelink-storage-dev \
  --query "networkRuleSet.ipRules"

# Test access
az storage container list \
  --account-name STORAGE_NAME \
  --auth-mode login \
  --query "[].name" -o table
```

**Note**: The Container App's outbound IP is automatically added during Step 8. You only need to add additional IPs for portal/local access.

### Issue 6: Subnet Delegation Error

**Error**: `ManagedEnvironmentSubnetIsDelegated`

**Solution**: The subnet shouldn't be pre-delegated. Our code handles this correctly, but if you manually created subnets, remove the delegation first.

---

## Cleanup

### Option 1: Automated Cleanup (Recommended)

**Windows**:
```powershell
.\scripts\destroy.ps1
```

**Linux/Mac**:
```bash
chmod +x scripts/destroy.sh
./scripts/destroy.sh
```

### Option 2: Manual Cleanup

```bash
cd terraform
terraform destroy -auto-approve
```

### Verify Cleanup

```bash
# List resource groups (should not show your privatelink groups)
az group list --query "[?starts_with(name, 'rg-privatelink')].name" -o table
```

---

## Cost Estimation

### Monthly Cost Breakdown (East US, Dev Environment)

| Service | Configuration | Estimated Cost/Month |
|---------|--------------|---------------------|
| Cosmos DB | 400 RU/s, 1GB | ~$24 |
| Storage Account | Standard LRS, minimal usage | ~$2 |
| Container Registry | Premium (required for PE) | ~$167 |
| Container App | 0.25 vCPU, 0.5GB, 1 replica | ~$15 |
| VNet & Subnets | Standard | Free |
| Private Endpoints | 2 endpoints | ~$14 |
| Private DNS Zones | 2 zones | ~$1 |
| Log Analytics | Basic tier, minimal logs | ~$5 |
| **TOTAL** | | **~$228/month** |

### Cost Optimization Tips

1. **Use Azure Calculator**: https://azure.microsoft.com/en-us/pricing/calculator/
2. **Cosmos DB**: Switch to serverless for dev/test
3. **Container Registry**: Use Basic SKU if not using private endpoints
4. **Container App**: Use scale-to-zero for dev environments
5. **Delete when not in use**: Run cleanup scripts when testing is done

---

## Additional Resources

- [Azure Private Link Documentation](https://docs.microsoft.com/en-us/azure/private-link/)
- [Container Apps Networking](https://docs.microsoft.com/en-us/azure/container-apps/networking)
- [Cosmos DB Private Endpoints](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-configure-private-endpoints)
- [Storage Account Private Endpoints](https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## Summary

✅ **What You've Built**:
- Complete Azure infrastructure with TRUE private connectivity
- Modular Terraform code for easy reuse
- Python Flask API to test private endpoints
- Secure networking with VNet integration
- Proper DNS resolution via private DNS zones

✅ **Security Achievements**:
- **NO** public internet access to Cosmos DB
- **NO** public internet access to Storage Account
- All traffic flows through private Azure backbone
- VNet-integrated Container App
- Private DNS for secure name resolution

🎉 **You now have a production-ready private endpoint setup!**
