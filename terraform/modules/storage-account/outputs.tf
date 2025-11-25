output "id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.storage.id
}

output "name" {
  description = "Storage account name"
  value       = azurerm_storage_account.storage.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}

output "connection_string" {
  description = "Storage account connection string"
  value       = azurerm_storage_account.storage.primary_connection_string
  sensitive   = true
}

output "container_name" {
  description = "Storage container name"
  value       = azurerm_storage_container.test_container.name
}
