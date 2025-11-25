variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "container_app_name" {
  description = "Name of the container app"
  type        = string
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Container App Environment"
  type        = string
}

variable "container_registry_url" {
  description = "Container registry URL"
  type        = string
}

variable "container_registry_username" {
  description = "Container registry username"
  type        = string
  sensitive   = true
}

variable "container_registry_password" {
  description = "Container registry password"
  type        = string
  sensitive   = true
}

variable "docker_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "cosmos_endpoint" {
  description = "Cosmos DB endpoint"
  type        = string
}

variable "cosmos_key" {
  description = "Cosmos DB key"
  type        = string
  sensitive   = true
}

variable "storage_connection_string" {
  description = "Storage account connection string"
  type        = string
  sensitive   = true
}

variable "storage_account_name" {
  description = "Storage account name"
  type        = string
}
