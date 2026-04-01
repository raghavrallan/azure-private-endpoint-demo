# Azure Private Endpoint Infrastructure with Terraform

This project demonstrates a complete Azure infrastructure setup with private endpoints for secure connectivity between Container Apps and Azure services (Cosmos DB and Storage Account).

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Virtual Network                         │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Container App Subnet (10.0.2.0/23)           │  │
│  │                                                       │  │
│  │   ┌──────────────────────────────────────────────┐  │  │
│  │   │     Container App (Python Flask API)         │  │  │
│  │   │  - Health Check endpoint                     │  │  │
│  │   │  - Cosmos DB test endpoint                   │  │  │
│  │   │  - Storage Account test endpoint             │  │  │
│  │   └──────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │     Private Endpoint Subnet (10.0.1.0/24)            │  │
│  │                                                       │  │
│  │  ┌─────────────────┐      ┌──────────────────────┐  │  │
│  │  │ Private Endpoint│      │  Private Endpoint    │  │  │
│  │  │   (Cosmos DB)   │      │  (Storage Account)   │  │  │
│  │  └─────────────────┘      └──────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Private DNS Zones:                                          │
│  - privatelink.documents.azure.com                           │
│  - privatelink.blob.core.windows.net                         │
└─────────────────────────────────────────────────────────────┘

External Resources:
┌───────────────────────────┐
│ Azure Container Registry  │ (Stores Docker images)
└───────────────────────────┘
```

## Features

- **Modular Terraform Configuration**: Separate modules for each service
- **Private Endpoints**: Secure connectivity for Cosmos DB and Storage Account
- **VNet Integration**: Container App integrated with Virtual Network
- **Separate Resource Groups**: Organized by service type
- **Python Flask API**: Test endpoints to verify private connectivity
- **Docker Support**: Containerized application deployment

## Resource Groups

1. `rg-privatelink-networking-dev` - Virtual Network and subnets
2. `rg-privatelink-cosmos-dev` - Cosmos DB resources
3. `rg-privatelink-storage-dev` - Storage Account resources
4. `rg-privatelink-acr-dev` - Container Registry
5. `rg-privatelink-app-dev` - Container App and environment

## Prerequisites

- Azure CLI (`az`) - [Install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Terraform (>= 1.0) - [Install](https://www.terraform.io/downloads)
- Docker - [Install](https://docs.docker.com/get-docker/)
- Azure subscription with appropriate permissions

## Project Structure

```
.
├── terraform/
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── terraform.tfvars.example   # Example variables file
│   └── modules/
│       ├── networking/            # VNet, subnets, private DNS zones
│       ├── cosmos-db/             # Cosmos DB with private endpoint
│       ├── storage-account/       # Storage Account with private endpoint
│       ├── container-registry/    # Azure Container Registry
│       └── container-app/         # Container App with VNet integration
├── app/
│   ├── main.py                    # Flask API application
│   ├── requirements.txt           # Python dependencies
│   ├── Dockerfile                 # Container image definition
│   └── .dockerignore              # Docker ignore patterns
└── scripts/
    ├── deploy.sh                  # Deployment script (Linux/Mac)
    ├── deploy.ps1                 # Deployment script (Windows)
    ├── destroy.sh                 # Cleanup script (Linux/Mac)
    └── destroy.ps1                # Cleanup script (Windows)
```

## Quick Start

### 1. Login to Azure

```bash
az login
az account set --subscription <your-subscription-id>
```

### 2. Configure Variables

Copy the example variables file and customize it:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your unique values:

```hcl
location     = "eastus"
environment  = "dev"
project_name = "privatelink"

# Must be globally unique
cosmos_db_name          = "cosmos-privatelink-dev-001"
storage_account_name    = "stprivatelinkdev001"      # lowercase, no hyphens
container_registry_name = "acrprivatelinkdev001"     # alphanumeric only

container_app_name = "api-app"
docker_image_tag   = "latest"
```

### 3. Deploy Using Automated Script

**Linux/Mac:**
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

**Windows:**
```powershell
.\scripts\deploy.ps1
```

### 4. Manual Deployment (Alternative)

If you prefer manual deployment:

**Step 1: Deploy Infrastructure**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Step 2: Build and Push Docker Image**
```bash
# Get ACR name from Terraform output
ACR_NAME=$(terraform output -raw container_registry_name)
ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push image
cd ../app
docker build -t ${ACR_LOGIN_SERVER}/api-app:latest .
docker push ${ACR_LOGIN_SERVER}/api-app:latest
```

**Step 3: Update Container App**
```bash
cd ../terraform
terraform apply -auto-approve
```

## Testing the Deployment

After deployment, test the endpoints:

```bash
# Get the Container App URL
CONTAINER_APP_URL=$(cd terraform && terraform output -raw container_app_url)

# Health check
curl $CONTAINER_APP_URL/

# Test Cosmos DB private endpoint
curl $CONTAINER_APP_URL/test-cosmos

# Test Storage Account private endpoint
curl $CONTAINER_APP_URL/test-storage
```

### Accessing Storage Containers from Azure Portal

The Storage Account is configured with firewall rules that allow access only from specific IPs. To access storage containers from the Azure Portal or locally, you need to add your IP address:

**Step 1: Get your public IP**
```bash
# Get your current public IP
curl -4 ifconfig.me
```

**Step 2: Add your IP to the storage account firewall**
```bash
# Replace with your actual IP and resource values
az storage account network-rule add \
  --account-name <your-storage-account-name> \
  --resource-group rg-privatelink-storage-dev \
  --ip-address <your-public-ip>
```

**Example:**
```bash
az storage account network-rule add \
  --account-name stpldev2024001 \
  --resource-group rg-privatelink-storage-dev \
  --ip-address 203.0.113.45
```

**Step 3: Verify access**
```bash
# List containers to verify access
az storage container list \
  --account-name <your-storage-account-name> \
  --auth-mode login \
  --query "[].name" -o table
```

**Note**: The Container App's outbound IP is automatically added to the firewall rules during deployment. If you're getting 403 errors when accessing storage containers, it means your IP hasn't been added to the allowed list yet.

## API Endpoints

### GET /
Health check endpoint
```json
{
  "status": "healthy",
  "message": "API is running",
  "endpoints": ["/", "/health", "/test-cosmos", "/test-storage"]
}
```

### GET /health
Detailed health check with configuration status
```json
{
  "status": "healthy",
  "configuration": {
    "cosmos_endpoint": "configured",
    "cosmos_key": "configured",
    "storage_connection": "configured",
    "storage_account_name": "stprivatelinkdev001"
  }
}
```

### GET /test-cosmos
Test Cosmos DB connectivity via private endpoint
```json
{
  "status": "success",
  "message": "Cosmos DB connection via private endpoint is working!",
  "private_endpoint_working": true,
  "database": "testdb",
  "container": "testcontainer",
  "endpoint": "https://cosmos-privatelink-dev-001.documents.azure.com:443/",
  "test_item_created": true,
  "total_items": 1
}
```

### GET /test-storage
Test Storage Account connectivity via private endpoint
```json
{
  "status": "success",
  "message": "Storage Account connection via private endpoint is working!",
  "private_endpoint_working": true,
  "storage_account": "stprivatelinkdev001",
  "container": "testcontainer",
  "container_exists": true,
  "test_blob_uploaded": true,
  "test_blob_content": "Testing private endpoint connection to Azure Storage",
  "total_blobs": 1
}
```

## Understanding Private Endpoints

### What are Private Endpoints?

Private Endpoints provide secure connectivity between Azure services by using private IP addresses from your Virtual Network. This means:

1. **No Public Internet**: Traffic stays within Azure backbone network
2. **Private IP Access**: Services are accessed via private IPs (10.0.x.x)
3. **DNS Resolution**: Private DNS zones resolve service names to private IPs
4. **Enhanced Security**: Public access can be disabled entirely

### How It Works

1. **Container App** runs in VNet-integrated subnet (10.0.2.0/23)
2. **Private Endpoints** are created in dedicated subnet (10.0.1.0/24)
3. **Private DNS Zones** resolve service FQDNs to private IPs
4. **Traffic Flow**: Container App → Private Endpoint → Service (all within VNet)

## Security Considerations

- **Cosmos DB**: Public network access is completely disabled. Access is only through private endpoint.
- **Storage Account**: Configured with firewall rules (default action: Deny)
  - Container App outbound IP is whitelisted
  - Private endpoint is enabled for VNet access
  - Only specified IPs can access via public endpoint
  - All other public access is blocked
- **VNet Integration**: Container App communicates with services through private endpoints
- **Private DNS**: Custom DNS zones ensure private IP resolution for services
- **Secrets Management**: Sensitive values (Cosmos DB key, storage connection string) stored as Container App secrets
- **Premium SKUs**: Container Registry uses Premium SKU for enterprise features

### Network Security Model

```
Public Internet Access:
├── Cosmos DB: ❌ Completely Disabled
└── Storage Account: ⚠️ Firewall-Restricted
    ├── Default Action: Deny
    ├── Allowed IPs: Container App + Your IP
    └── Azure Services: Bypass Enabled

Private Endpoint Access:
├── Cosmos DB: ✅ Active (only access method)
└── Storage Account: ✅ Active (preferred method)
```

## Cost Optimization

To minimize costs:

1. Use smaller SKUs for development:
   - Cosmos DB: 400 RU/s provisioned throughput
   - Storage Account: Standard LRS
   - Container App: 0.25 CPU / 0.5Gi Memory

2. Consider these for production:
   - Cosmos DB: Autoscale or serverless
   - Storage Account: Zone-redundant storage (ZRS)
   - Container App: Increase replicas and resources

## Cleanup

To destroy all resources:

**Linux/Mac:**
```bash
./scripts/destroy.sh
```

**Windows:**
```powershell
.\scripts\destroy.ps1
```

Or manually:
```bash
cd terraform
terraform destroy
```

## Troubleshooting

### Issue: 403 Forbidden when accessing Storage Containers
**Problem**: Getting "403 Forbidden" or "Authorization failed" when trying to access storage containers from Azure Portal.

**Solution**: Your IP address needs to be added to the storage account firewall rules.

```bash
# Get your current public IP
curl -4 ifconfig.me

# Add your IP to storage firewall
az storage account network-rule add \
  --account-name <storage-account-name> \
  --resource-group rg-privatelink-storage-dev \
  --ip-address <your-ip-address>

# Verify the rule was added
az storage account show \
  --name <storage-account-name> \
  --resource-group rg-privatelink-storage-dev \
  --query "networkRuleSet.ipRules"
```

### Issue: Terraform fails with "name already exists"
**Solution**: Azure resource names must be globally unique. Change the names in `terraform.tfvars`.

### Issue: Container App shows "Provisioning failed"
**Solution**: Check logs with `az containerapp logs show` or verify VNet subnet has correct delegation.

### Issue: Container App cannot access storage
**Problem**: App logs show connection errors to storage account.

**Solution**: Verify the Container App's outbound IP is in the storage firewall rules:
```bash
# Get Container App outbound IP
az containerapp show \
  --name <app-name> \
  --resource-group rg-privatelink-app-dev \
  --query "properties.outboundIpAddresses" -o json

# Add the IP to storage firewall
az storage account network-rule add \
  --account-name <storage-account-name> \
  --resource-group rg-privatelink-storage-dev \
  --ip-address <container-app-ip>
```

### Issue: Private endpoint connection fails
**Solution**:
- Verify private DNS zones are linked to VNet
- Check subnet has `private_endpoint_network_policies_enabled = false`
- Ensure Container App subnet has proper delegation

### Issue: Docker push fails
**Solution**:
- Ensure logged in: `az acr login --name <acr-name>`
- Verify ACR name is alphanumeric only (no hyphens or underscores)

## Additional Resources

- [Azure Private Endpoints](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [Container Apps VNet Integration](https://docs.microsoft.com/en-us/azure/container-apps/vnet-custom)
- [Cosmos DB Private Link](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-configure-private-endpoints)
- [Storage Account Private Endpoints](https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints)

## License

MIT License - Feel free to use this project as a template for your own infrastructure.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

<!-- activity: init -->
