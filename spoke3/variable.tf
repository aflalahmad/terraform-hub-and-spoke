variable "rg" {
  type = object({
    resource_group = string
    location       = string
  })
  validation {
    condition     = length(keys(var.rg)) > 0
    error_message = "The resource group must not be empty"
  }
  description = "Specifies the resource group details."
}

variable "appserviceplan_name" {
  type        = string
  description = "Name of the App Service Plan."
}

variable "appservice_name" {
  type        = string
  description = "Name of the App Service."
}

variable "vnet_details" {
  type = map(object({
    vnet_name = string
    address_space = string
  }))
  description = "The details of the VNET"
}

variable "subnet_details" {
  type        = map(object({
    subnet_name      = string
    address_prefixes = string
  }))
  description = "Map of subnet details."
  validation {
    condition     = length(keys(var.subnet_details)) > 0
    error_message = "At least one subnet detail must be defined."
  }
}

