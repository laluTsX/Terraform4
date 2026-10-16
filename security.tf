resource "azurerm_network_security_group" "app" {
    name                = "nsg-app"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags
}

resource "azurerm_network_security_group" "db" {
    name                = "nsg-db"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags

    security_rule {
        name                       = "Allow-PG-desde-app-y-vm"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "5432"
        source_address_prefixes    = [local.cidr_app, local.cidr_vm]
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Deny-todo-entrante"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_security_group" "vm" {
    name                = "nsg-vm"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags

    security_rule {
        name                       = "Allow-SSH-desde-Bastion"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = local.cidr_bastion
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Deny-todo-entrante"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_security_group" "endpoints" {
    name                = "nsg-endpoints"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags

    security_rule {
        name                       = "Allow-HTTPS-desde-app-y-vm"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefixes    = [local.cidr_app, local.cidr_vm]
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Deny-todo-entrante"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Reglas obligatorias para que Azure Bastion funcione con NSG
resource "azurerm_network_security_group" "bastion" {
    name                = "nsg-bastion"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags

    security_rule {
        name                       = "Allow-HTTPS-Internet"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "Allow-GatewayManager"
        priority                   = 130
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "GatewayManager"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "Allow-AzureLoadBalancer"
        priority                   = 140
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "Allow-Bastion-Comunicacion-In"
        priority                   = 150
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["8080", "5701"]
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }
    security_rule {
        name                       = "Allow-SSH-RDP-Out"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["22", "3389"]
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
    }
    security_rule {
        name                       = "Allow-AzureCloud-Out"
        priority                   = 110
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "AzureCloud"
    }
    security_rule {
        name                       = "Allow-Bastion-Comunicacion-Out"
        priority                   = 120
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["8080", "5701"]
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }
    security_rule {
        name                       = "Allow-HTTP-Out"
        priority                   = 130
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "Internet"
    }
}

resource "azurerm_subnet_network_security_group_association" "app" {
    subnet_id                 = azurerm_subnet.app.id
    network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
    subnet_id                 = azurerm_subnet.db.id
    network_security_group_id = azurerm_network_security_group.db.id
}

resource "azurerm_subnet_network_security_group_association" "vm" {
    subnet_id                 = azurerm_subnet.vm.id
    network_security_group_id = azurerm_network_security_group.vm.id
}

resource "azurerm_subnet_network_security_group_association" "endpoints" {
    subnet_id                 = azurerm_subnet.endpoints.id
    network_security_group_id = azurerm_network_security_group.endpoints.id
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
    subnet_id                 = azurerm_subnet.bastion.id
    network_security_group_id = azurerm_network_security_group.bastion.id
}