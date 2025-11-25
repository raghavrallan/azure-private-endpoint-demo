output "app_id" {
  description = "Container app ID"
  value       = azurerm_container_app.app.id
}

output "app_url" {
  description = "Container app URL"
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}

output "app_fqdn" {
  description = "Container app FQDN"
  value       = azurerm_container_app.app.ingress[0].fqdn
}

output "environment_id" {
  description = "Container app environment ID"
  value       = azurerm_container_app_environment.env.id
}
