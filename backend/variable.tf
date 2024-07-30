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

variable "stgacc_name" {
  description = "The name of the Azure Storage Account. Must be unique within Azure."
  type        = string
}

variable "container_name" {
  description = "The name of the Storage Account Container used to store state files."
  type        = string
}
