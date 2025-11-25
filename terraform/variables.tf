variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "privatelink"
}

variable "cosmos_db_name" {
  description = "Cosmos DB account name"
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name (must be globally unique)"
  type        = string
}

variable "container_registry_name" {
  description = "Container registry name (must be globally unique)"
  type        = string
}

variable "container_app_name" {
  description = "Container app name"
  type        = string
  default     = "api-app"
}

variable "docker_image_tag" {
  description = "Docker image tag for the container app"
  type        = string
  default     = "latest"
}
