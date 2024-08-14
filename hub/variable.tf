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

variable "publicip_names" {
  type        = map(object({
    name = string
  }))
  description = "Map of public IP names."
}

variable "bastionhost_name" {
  type        = string
  description = "Name of the Bastion host."
}

variable "subnet_details" {
  type        = map(object({
    subnet_name       = string
    address_prefixes  = string
    delegations       = list(object({
      name              = string
      service_delegation = string
      actions           = list(string)
    }))
  }))
  description = "Map of subnet details."
  validation {
    condition     = length(keys(var.subnet_details)) > 0
    error_message = "At least one subnet detail must be defined."
  }
}

variable "vnet_peerings" {
  type        = map(object({
    allow_forwarded_traffic      = bool
    allow_gateway_transit        = bool
    allow_virtual_network_access = bool
  }))
  description = "Map of VNet peering settings."
}

variable "virtual_network_gateway_name" {
  type = string
}
variable "firewall_name" {
  type = string
}
variable "firewall_policy_name" {
  type = string
}

variable "hub_local_network_gateway_name" {
  type        = string
  description = "Name of the hub's local network gateway."
}

variable "vnet_gateway_connection" {
  type = string
}