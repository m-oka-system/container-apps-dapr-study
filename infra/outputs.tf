output "AZURE_CONTAINER_REGISTRY_ENDPOINT" {
  value = azurerm_container_registry.cr.login_server
}
