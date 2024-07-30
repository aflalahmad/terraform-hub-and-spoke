terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.1.0"
    }
  }
  required_version = ">= 1.1.0"
  backend "azurerm" {
    resource_group_name  = "backendRG"
    storage_account_name = "backednstgacc"
    container_name       = "mycontainer"
    key                  = "onoremise.tfstate"
  }
}

provider "azurerm" {
  features {}
}
