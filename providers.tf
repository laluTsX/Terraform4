terraform {
    required_version = ">= 1.5.0"

    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 4.0"
        }
        random = {
            source  = "hashicorp/random"
            version = "~> 3.6"
        }
    }
}

provider "azurerm" {
    features {}
    subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
    length  = 5
    special = false
    upper   = false
}