locals {
  # タグ
  tags = { azd-env-name : var.environment_name }

  # Azure ポータルの IP アドレス
  azure_portal_ips = {
    cosmosdb = "13.91.105.215,4.210.172.107,13.88.56.148,40.91.218.243" # https://learn.microsoft.com/ja-jp/azure/cosmos-db/how-to-configure-firewall
  }

  # プライベートエンドポイント
  private_endpoint = {
    kv = {
      name                           = azurerm_key_vault.kv.name
      private_dns_zone_ids           = try([azurerm_private_dns_zone.zone["kv"].id], [])
      subresource_names              = ["vault"]
      private_connection_resource_id = azurerm_key_vault.kv.id
    }
    cosmos = {
      name                           = azurerm_cosmosdb_account.account.name
      private_dns_zone_ids           = try([azurerm_private_dns_zone.zone["cosmos"].id], [])
      subresource_names              = ["Sql"]
      private_connection_resource_id = azurerm_cosmosdb_account.account.id
    }
  }

  # Application Gateway
  application_gateway = {
    sites = [
      {
        name         = "frontend"
        host_name    = var.custom_domain_name
        backend_fqdn = azurerm_container_app.ca["frontend"].ingress[0].fqdn
        priority     = 10
      },
    ]
  }

  # Dapr コンポーネント
  dapr_components = {
    secret-store = {
      component_type = "secretstores.azure.keyvault"
      version        = "v1"
      metadata = [
        {
          name  = "vaultName"
          value = try(azurerm_key_vault.kv.name, "")
        },
        {
          name  = "azureClientId"
          value = try(azurerm_user_assigned_identity.id["ca"].client_id, "")
        },
      ]
      secretStoreComponent = ""
    }
    product-store = {
      component_type = "state.azure.cosmosdb"
      version        = "v1"
      metadata = [
        {
          name  = "url"
          value = try(azurerm_cosmosdb_account.account.endpoint, "")
        },
        {
          name  = "database"
          value = try(azurerm_cosmosdb_sql_database.database.name, "")
        },
        {
          name  = "collection"
          value = try(azurerm_cosmosdb_sql_container.container.name, "")
        },
        {
          name      = "masterKey"
          secretRef = "COSMOSDB-PRIMARY-KEY"
        }
      ]
      secretStoreComponent = "secret-store"
    }
  }

  # リソースログ (診断設定)
  diagnostic_setting_target_resources = merge(
    { "cae" = azurerm_container_app_environment.cae.id },
  )

  # コンテナアプリの環境変数
  container_app_env = {
    frontend = {
      API_BASE_URL = "http://ca-backend"
    }
    backend = {
    }
  }
}
