# ---------- Storage Account (Blob) ----------
resource "azurerm_storage_account" "st" {
    name                            = "st${var.prefix}${random_string.suffix.result}"
    resource_group_name             = azurerm_resource_group.rg.name
    location                        = azurerm_resource_group.rg.location
    account_tier                    = "Standard"
    account_replication_type        = "LRS"
    min_tls_version                 = "TLS1_2"
    public_network_access_enabled   = false
    allow_nested_items_to_be_public = false
    tags                            = var.tags
}

# ---------- PostgreSQL Flexible Server ----------
resource "random_password" "db" {
    length           = 24
    special          = true
    override_special = "!#%*-_"
}

resource "azurerm_postgresql_flexible_server" "pg" {
    name                          = "psql-${var.prefix}-${random_string.suffix.result}"
    resource_group_name           = azurerm_resource_group.rg.name
    location                      = azurerm_resource_group.rg.location
    version                       = "16"
    sku_name                      = var.db_sku
    storage_mb                    = 32768
    administrator_login           = "pgadmin"
    administrator_password        = random_password.db.result
    public_network_access_enabled = false
    tags                          = var.tags

    authentication {
        active_directory_auth_enabled = true
        password_auth_enabled         = true
        tenant_id                     = data.azurerm_client_config.current.tenant_id
    }

    lifecycle {
        ignore_changes = [zone]
    }
}

# ---------- Zonas Private DNS ----------
resource "azurerm_private_dns_zone" "pg" {
    name                = "privatelink.postgres.database.azure.com"
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "blob" {
    name                = "privatelink.blob.core.windows.net"
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg" {
    name                  = "link-pg"
    resource_group_name   = azurerm_resource_group.rg.name
    private_dns_zone_name = azurerm_private_dns_zone.pg.name
    virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
    name                  = "link-blob"
    resource_group_name   = azurerm_resource_group.rg.name
    private_dns_zone_name = azurerm_private_dns_zone.blob.name
    virtual_network_id    = azurerm_virtual_network.vnet.id
}

# ---------- Private Endpoints ----------
resource "azurerm_private_endpoint" "pg" {
    name                = "pe-postgres"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    subnet_id           = azurerm_subnet.db.id
    tags                = var.tags

    private_service_connection {
        name                           = "psc-postgres"
        private_connection_resource_id = azurerm_postgresql_flexible_server.pg.id
        subresource_names              = ["postgresqlServer"]
        is_manual_connection           = false
    }

    ip_configuration {
        name               = "ipconfig-pg"
        private_ip_address = "10.0.2.4"
        subresource_name   = "postgresqlServer"
    }

    private_dns_zone_group {
        name                 = "pg-dns"
        private_dns_zone_ids = [azurerm_private_dns_zone.pg.id]
    }
}

resource "azurerm_private_endpoint" "blob" {
    name                = "pe-blob"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    subnet_id           = azurerm_subnet.endpoints.id
    tags                = var.tags

    private_service_connection {
        name                           = "psc-blob"
        private_connection_resource_id = azurerm_storage_account.st.id
        subresource_names              = ["blob"]
        is_manual_connection           = false
    }

    ip_configuration {
        name               = "ipconfig-blob"
        private_ip_address = "10.0.4.4"
        subresource_name   = "blob"
    }

    private_dns_zone_group {
        name                 = "blob-dns"
        private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
    }
}