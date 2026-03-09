# PostgreSQL Outputs
output "postgresql_host" {
  value = azurerm_postgresql_flexible_server.fs.fqdn
}

output "postgresql_port" {
  value = 5432
}

output "postgresql_username" {
  value = azurerm_postgresql_flexible_server.fs.administrator_login
}

output "postgresql_password" {
  value = azurerm_postgresql_flexible_server.fs.administrator_password
}

output "postgresql_connection_string" {
  value = "postgresql://${azurerm_postgresql_flexible_server.fs.administrator_login}:${azurerm_postgresql_flexible_server.fs.administrator_password}@${azurerm_postgresql_flexible_server.fs.fqdn}:5432/postgres"
  description = "PostgreSQL connection string"
}

# ACR Outputs
output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "ACR login server URL"
}

output "acr_username" {
  value       = azurerm_container_registry.acr.admin_username
  description = "ACR admin username"
}

output "acr_password" {
  value       = azurerm_container_registry.acr.admin_password
  description = "ACR admin password"
}