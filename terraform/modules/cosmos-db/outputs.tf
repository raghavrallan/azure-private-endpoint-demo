output "id" {
  description = "Cosmos DB account ID"
  value       = azurerm_cosmosdb_account.cosmos.id
}

output "name" {
  description = "Cosmos DB account name"
  value       = azurerm_cosmosdb_account.cosmos.name
}

output "endpoint" {
  description = "Cosmos DB endpoint"
  value       = azurerm_cosmosdb_account.cosmos.endpoint
}

output "primary_key" {
  description = "Cosmos DB primary master key"
  value       = azurerm_cosmosdb_account.cosmos.primary_key
  sensitive   = true
}

output "connection_strings" {
  description = "Cosmos DB connection strings"
  value       = azurerm_cosmosdb_account.cosmos.connection_strings
  sensitive   = true
}

output "database_name" {
  description = "Cosmos DB database name"
  value       = azurerm_cosmosdb_sql_database.db.name
}

output "container_name" {
  description = "Cosmos DB container name"
  value       = azurerm_cosmosdb_sql_container.container.name
}
