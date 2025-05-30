output "AZURE_CONTAINER_REGISTRY_ENDPOINT" {
  value = azurerm_container_registry.cr.login_server
}

# Easy Auth outputs
output "FRONTEND_AUTH_CLIENT_ID" {
  value       = azuread_application.frontend_auth.client_id
  description = "Azure AD Application Client ID for frontend authentication"
}

output "FRONTEND_AUTH_OBJECT_ID" {
  value       = azuread_application.frontend_auth.object_id
  description = "Azure AD Application Object ID for frontend authentication"
}

output "FRONTEND_URL" {
  value       = "https://${azurerm_container_app.ca["frontend"].latest_revision_fqdn}"
  description = "Frontend Container App URL"
}
