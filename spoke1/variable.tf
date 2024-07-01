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

variable "vnets" {
  type = map(object({
    address_space  = string
  }))
   description = "The virtual network value must not be empty"
}

variable "subnets" {
    type = map(object({
      name = string
      vnet = string
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

variable "vms" {
  type = map(object({
    vm_name = string
    nic_name = string
    host_name = string
    disk_name = string 
    vm_size = string
    admin_username = string
    admin_password = string
    data_disk_size_gb = number
    subnet = string
  }))
}


variable "keyvault_name" {
  type = string
  
}