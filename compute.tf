# ---------- App Service ----------
resource "azurerm_service_plan" "plan" {
    name                = "asp-${var.prefix}-prod"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    os_type             = "Linux"
    sku_name            = "B1"
    tags                = var.tags
}

resource "azurerm_linux_web_app" "app" {
    name                      = "app-${var.prefix}-${random_string.suffix.result}"
    resource_group_name       = azurerm_resource_group.rg.name
    location                  = azurerm_resource_group.rg.location
    service_plan_id           = azurerm_service_plan.plan.id
    virtual_network_subnet_id = azurerm_subnet.app.id
    https_only                = true
    tags                      = var.tags

    identity {
        type = "SystemAssigned"
    }

    site_config {
        vnet_route_all_enabled = true
        application_stack {
        python_version = "3.12"
        }
    }

    app_settings = {
        PG_HOST  = azurerm_postgresql_flexible_server.pg.fqdn
        BLOB_URL = azurerm_storage_account.st.primary_blob_endpoint
    }
}

# ---------- VM worker ----------
resource "random_password" "vm" {
    length           = 20
    special          = true
    override_special = "!#%*-_"
}

resource "azurerm_network_interface" "vm" {
    name                = "nic-vm-worker"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.vm.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_linux_virtual_machine" "vm" {
    name                            = "vm-worker"
    resource_group_name             = azurerm_resource_group.rg.name
    location                        = azurerm_resource_group.rg.location
    size                            = var.vm_size
    admin_username                  = "azureuser"
    admin_password                  = random_password.vm.result
    disable_password_authentication = false
    network_interface_ids           = [azurerm_network_interface.vm.id]
    tags                            = var.tags

    identity {
        type = "SystemAssigned"
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
    }
}

# ---------- RBAC: identidades administradas -> Blob ----------
resource "azurerm_role_assignment" "app_blob" {
    scope                = azurerm_storage_account.st.id
    role_definition_name = "Storage Blob Data Contributor"
    principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

resource "azurerm_role_assignment" "vm_blob" {
    scope                = azurerm_storage_account.st.id
    role_definition_name = "Storage Blob Data Contributor"
    principal_id         = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}