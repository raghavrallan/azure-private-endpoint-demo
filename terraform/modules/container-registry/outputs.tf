output "id" {
  description = "Container registry ID"
  value       = azurerm_container_registry.acr.id
}

output "name" {
  description = "Container registry name"
  value       = azurerm_container_registry.acr.name
}

output "login_server" {
  description = "Container registry login server"
  value       = azurerm_container_registry.acr.login_server
}

output "admin_username" {
  description = "Container registry admin username"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "Container registry admin password"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}
