# Log Analytics Workspace for Container App
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "logs-${var.container_app_name}-${var.environment_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment_name
    ManagedBy   = "Terraform"
  }
}

# Container App Environment with VNet integration
resource "azurerm_container_app_environment" "env" {
  name                       = "cae-${var.environment_name}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  infrastructure_subnet_id   = var.subnet_id
  internal_load_balancer_enabled = false

  tags = {
    Environment = var.environment_name
    ManagedBy   = "Terraform"
  }
}

# Container App
resource "azurerm_container_app" "app" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "api-app"
      image  = "${var.container_registry_url}/${var.container_app_name}:${var.docker_image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "COSMOS_ENDPOINT"
        value = var.cosmos_endpoint
      }

      env {
        name        = "COSMOS_KEY"
        secret_name = "cosmos-key"
      }

      env {
        name        = "STORAGE_CONNECTION_STRING"
        secret_name = "storage-connection-string"
      }

      env {
        name  = "STORAGE_ACCOUNT_NAME"
        value = var.storage_account_name
      }

      env {
        name  = "PORT"
        value = "8000"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  registry {
    server               = var.container_registry_url
    username             = var.container_registry_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = var.container_registry_password
  }

  secret {
    name  = "cosmos-key"
    value = var.cosmos_key
  }

  secret {
    name  = "storage-connection-string"
    value = var.storage_connection_string
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    Environment = var.environment_name
    ManagedBy   = "Terraform"
  }
}
