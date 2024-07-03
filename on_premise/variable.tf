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
  type = string
  
}

variable "subnet_details"{
  type = map(object({
    subnet_name = string
    address_prefixes = string
  }))
}

variable "public_ip_name" {
  type = string
}

variable "onprem_local_network_gateway_name" {
  type = string
}