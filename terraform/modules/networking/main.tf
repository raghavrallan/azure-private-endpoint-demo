# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  private_endpoint_network_policies_enabled = false
}

# Subnet for Container Apps
resource "azurerm_subnet" "container_apps" {
  name                 = "snet-container-apps"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/23"]

  # Don't pre-delegate the subnet - Container App Environment will handle delegation automatically
}

# Private DNS Zone for Cosmos DB
resource "azurerm_private_dns_zone" "cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Link Cosmos DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_link" {
  name                  = "cosmos-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos.name
  virtual_network_id    = azurerm_virtual_network.vnet.id

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Private DNS Zone for Storage Account (Blob)
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Link Storage DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage_link" {
  name                  = "storage-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
