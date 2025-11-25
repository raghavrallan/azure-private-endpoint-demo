output "container_registry_login_server" {
  description = "Container registry login server URL"
  value       = module.container_registry.login_server
}

output "container_registry_name" {
  description = "Container registry name"
  value       = module.container_registry.name
}

output "container_app_url" {
  description = "Container app URL"
  value       = module.container_app.app_url
}

output "cosmos_db_endpoint" {
  description = "Cosmos DB endpoint"
  value       = module.cosmos_db.endpoint
}

output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage_account.name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "resource_groups" {
  description = "All resource group names"
  value = {
    networking         = azurerm_resource_group.networking.name
    cosmos            = azurerm_resource_group.cosmos.name
    storage           = azurerm_resource_group.storage.name
    container_registry = azurerm_resource_group.container_registry.name
    container_app     = azurerm_resource_group.container_app.name
  }
}
