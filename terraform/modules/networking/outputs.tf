output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.vnet.name
}

output "private_endpoint_subnet_id" {
  description = "Private endpoint subnet ID"
  value       = azurerm_subnet.private_endpoints.id
}

output "container_app_subnet_id" {
  description = "Container app subnet ID"
  value       = azurerm_subnet.container_apps.id
}

output "cosmos_private_dns_zone_id" {
  description = "Cosmos DB private DNS zone ID"
  value       = azurerm_private_dns_zone.cosmos.id
}

output "storage_private_dns_zone_id" {
  description = "Storage account private DNS zone ID"
  value       = azurerm_private_dns_zone.storage_blob.id
}
