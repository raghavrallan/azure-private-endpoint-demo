variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "container_registry_name" {
  description = "Name of the container registry"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
