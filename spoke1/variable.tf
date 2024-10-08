variable "rg" {
  type = object({
    resource_group = string
    location       = string
  })
  validation {
    condition     = length(var.rg) > 0
    error_message = "The resource group must not be empty"
  }
  description = "Specifies the resource group details."
}

variable "vnets" {
  type        = map(object({
    vnet_name = string
    address_space = string
  }))
  description = "Map of virtual network details."
  validation {
    condition     = length(keys(var.vnets)) > 0
    error_message = "At least one virtual network must be defined."
  }
}

variable "subnets" {
  type        = map(object({
    name             = string
    vnet             = string
    address_prefixes = string
  }))
  description = "Map of subnet configurations."
  validation {
    condition     = length(keys(var.subnets)) > 0
    error_message = "At least one subnet must be defined."
  }
}


variable "rules_file" {
  type        = string
  default     = "rules-20.csv"
  description = "Name of the CSV file containing rules."
  validation {
    condition     = can(regex(".*\\.csv$", var.rules_file))
    error_message = "Rules file must be in CSV format."
  }
}

variable "vms" {
  type        = map(object({
    vm_name          = string
    nic_name         = string
    host_name        = string
    disk_name        = string
    vm_size          = string
    admin_username   = string
    admin_password   = string
    data_disk_size_gb = number
    subnet           = string
  }))
  description = "Map of virtual machine configurations."
  validation {
    condition     = length(keys(var.vms)) > 0
    error_message = "At least one virtual machine must be defined."
  }
}



variable "rsv_name" {
  type        = string
  description = "Name of the Reserved Instance."
}

variable "backuppolicy_name" {
  type        = string
  description = "Name of the backup policy."
}

