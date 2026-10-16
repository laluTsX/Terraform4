resource "azurerm_public_ip" "bastion" {
    name                = "pip-bastion"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = var.tags
}

resource "azurerm_bastion_host" "bastion" {
    name                = "bas-lz-prod"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku                 = "Basic"
    tags                = var.tags

    ip_configuration {
        name                 = "ipconfig"
        subnet_id            = azurerm_subnet.bastion.id
        public_ip_address_id = azurerm_public_ip.bastion.id
    }
}