resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Allow public access during creation, will be disabled after private endpoint is ready
  public_network_access_enabled = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create a blob container for testing
resource "azurerm_storage_container" "test_container" {
  name                  = "testcontainer"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"

  depends_on = [azurerm_storage_account.storage]
}

# Create a blob container for user uploads
resource "azurerm_storage_container" "uploads_container" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"

  depends_on = [azurerm_storage_account.storage]
}

# Private Endpoint for Storage Account (Blob)
resource "azurerm_private_endpoint" "storage_blob_pe" {
  name                = "pe-${var.storage_account_name}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "psc-${var.storage_account_name}-blob"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-storage-blob"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
