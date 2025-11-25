terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "1fc66efc-2ddc-4018-a0d6-a513dc7f219c"

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Resource Groups
resource "azurerm_resource_group" "networking" {
  name     = "rg-${var.project_name}-networking-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "cosmos" {
  name     = "rg-${var.project_name}-cosmos-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "storage" {
  name     = "rg-${var.project_name}-storage-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "container_registry" {
  name     = "rg-${var.project_name}-acr-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "container_app" {
  name     = "rg-${var.project_name}-app-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.networking.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
}

# Container Registry Module
module "container_registry" {
  source = "./modules/container-registry"

  resource_group_name      = azurerm_resource_group.container_registry.name
  location                 = var.location
  container_registry_name  = var.container_registry_name
  environment              = var.environment
}

# Cosmos DB Module with Private Endpoint
module "cosmos_db" {
  source = "./modules/cosmos-db"

  resource_group_name     = azurerm_resource_group.cosmos.name
  location                = var.location
  cosmos_db_name          = var.cosmos_db_name
  environment             = var.environment

  # Private endpoint configuration
  pe_subnet_id            = module.networking.private_endpoint_subnet_id
  private_dns_zone_id     = module.networking.cosmos_private_dns_zone_id
}

# Storage Account Module with Private Endpoint
module "storage_account" {
  source = "./modules/storage-account"

  resource_group_name     = azurerm_resource_group.storage.name
  location                = var.location
  storage_account_name    = var.storage_account_name
  environment             = var.environment

  # Private endpoint configuration
  pe_subnet_id            = module.networking.private_endpoint_subnet_id
  private_dns_zone_id     = module.networking.storage_private_dns_zone_id
}

# Container App Module
module "container_app" {
  source = "./modules/container-app"

  resource_group_name         = azurerm_resource_group.container_app.name
  location                    = var.location
  container_app_name          = var.container_app_name
  environment_name            = var.environment

  # VNet integration
  subnet_id                   = module.networking.container_app_subnet_id

  # Container configuration
  container_registry_url      = module.container_registry.login_server
  container_registry_username = module.container_registry.admin_username
  container_registry_password = module.container_registry.admin_password
  docker_image_tag            = var.docker_image_tag

  # Environment variables for app
  cosmos_endpoint             = module.cosmos_db.endpoint
  cosmos_key                  = module.cosmos_db.primary_key
  storage_connection_string   = module.storage_account.connection_string
  storage_account_name        = module.storage_account.name
}
