locals {
    cidr_app       = "10.0.1.0/24"
    cidr_db        = "10.0.2.0/24"
    cidr_vm        = "10.0.3.0/24"
    cidr_endpoints = "10.0.4.0/24"
    cidr_bastion   = "10.0.5.0/24"
}

resource "azurerm_resource_group" "rg" {
    name     = "rg-${var.prefix}-prod"
    location = var.location
    tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
    name                = "vnet-lz-prod"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags
}

resource "azurerm_subnet" "app" {
    name                 = "snet-app"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [local.cidr_app]

    delegation {
        name = "serverfarms"
        service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
    }
}

resource "azurerm_subnet" "db" {
    name                              = "snet-db"
    resource_group_name               = azurerm_resource_group.rg.name
    virtual_network_name              = azurerm_virtual_network.vnet.name
    address_prefixes                  = [local.cidr_db]
    private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet" "vm" {
    name                 = "snet-vm"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [local.cidr_vm]
}

resource "azurerm_subnet" "endpoints" {
    name                              = "snet-endpoints"
    resource_group_name               = azurerm_resource_group.rg.name
    virtual_network_name              = azurerm_virtual_network.vnet.name
    address_prefixes                  = [local.cidr_endpoints]
    private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet" "bastion" {
    name                 = "AzureBastionSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [local.cidr_bastion]
}