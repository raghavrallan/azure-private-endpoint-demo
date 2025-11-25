resource "azurerm_cosmosdb_account" "cosmos" {
  name                = var.cosmos_db_name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # Allow public access during creation, can be disabled later for full private endpoint usage
  public_network_access_enabled = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create Cosmos DB database
resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "testdb"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  throughput          = 400
}

# Create Cosmos DB container for testing
resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "testcontainer"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/id"
  throughput          = 400
}

# Create Cosmos DB container for user data
resource "azurerm_cosmosdb_sql_container" "userdata" {
  name                = "userdata"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/id"
  throughput          = 400
}

# Private Endpoint for Cosmos DB
resource "azurerm_private_endpoint" "cosmos_pe" {
  name                = "pe-${var.cosmos_db_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "psc-${var.cosmos_db_name}"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-cosmos"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
