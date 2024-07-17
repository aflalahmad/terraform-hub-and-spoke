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

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network."
}
