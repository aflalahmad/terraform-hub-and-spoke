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


variable "subnets"{
  type = map(object({
    name=string
    vnet=string
    address_prefixes = string
  }))
}


variable "nsg_count" {
  type = string
     default = 2
     description = "The count value must be in number "
}

variable "rules_file" {
    type = string
    default = "rules-20.csv"
    description = "The rules files must be saved in .csv file name."
  
}

variable "vmss_name"{
  type = string
}

variable "admin_username"{
  type = string
}

variable "admin_password"{
  type = string
}

variable "sku"{
  type = string
  }

variable "instance" {

  type   = number
}