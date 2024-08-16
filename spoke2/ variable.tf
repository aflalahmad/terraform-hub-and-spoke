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

variable "nsg_count" {
  type        = string
  default     = "2"
  description = "Number of NSGs to deploy."
  validation {
    condition     = can(regex("^\\d+$", var.nsg_count))
    error_message = "NSG count must be a valid number."
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

variable "vmss_name" {
  type        = string
  description = "Name of the Virtual Machine Scale Set (VMSS)."
}

variable "admin_username" {
  type        = string
  description = "Admin username for virtual machines."
}

variable "admin_password" {
  type        = string
  description = "Admin password for virtual machines."
}

variable "sku" {
  type        = string
  description = "SKU of the product."
}

variable "instance" {
  type        = number
  description = "Instance count."
}

variable "rsv_name" {
  type        = string
  description = "Name of the Reserved Instance."
}

variable "backuppolicy_name" {
  type        = string
  description = "Name of the backup policy."
}
