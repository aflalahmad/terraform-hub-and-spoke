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


variable "appserviceplan_name" {
  type = string
  
}
variable "appservice_name" {
  type = string
}