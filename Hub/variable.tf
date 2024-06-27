variable "rg" {
    type = object({
      resource_group =string
      location  = string 
    })
    validation {
      condition = length(var.rg)>0
      error_message = "The resource group must not be empty"
    }
}
variable "vnet_name" {
  type = string
}

variable "address_space" {
  type = list(string)
  
}

variable "subnet_name" {
  type = string
}

variable "address_prefixes" {
  type = list(string)
  
}
variable "vnet_peerings" {
    type = map(object({
        allow_forwarded_traffic     = bool
        allow_gateway_transit       = bool
        allow_virtual_network_access = bool
    }))
    
    default = {}
}