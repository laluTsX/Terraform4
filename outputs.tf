output "app_url" {
    value = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "pg_fqdn" {
    value = azurerm_postgresql_flexible_server.pg.fqdn
}

output "blob_host" {
    value = "${azurerm_storage_account.st.name}.blob.core.windows.net"
}

output "vm_admin_password" {
    value     = random_password.vm.result
    sensitive = true
}