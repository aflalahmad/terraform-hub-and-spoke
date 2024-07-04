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

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network."
}

variable "address_space" {
  type        = string
  description = "Address space for the virtual network."
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

variable "public_ip_name" {
  type        = string
  description = "Name of the public IP."
}

variable "onprem_local_network_gateway_name" {
  type        = string
  description = "Name of the on-premises local network gateway."
}
