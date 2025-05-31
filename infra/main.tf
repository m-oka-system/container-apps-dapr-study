data "azurerm_client_config" "current" {}

resource "random_integer" "num" {
  min = 10000
  max = 99999
}

# ------------------------------------------------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.environment_name}"
  location = var.location

  tags = local.tags
}

# ------------------------------------------------------------------------------------------------------
# Virtual Network
# ------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.vnet.address_space

  tags = local.tags
}

resource "azurerm_subnet" "subnet" {
  for_each                          = var.subnet
  name                              = "snet-${each.value.name}"
  resource_group_name               = azurerm_resource_group.rg.name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = each.value.address_prefixes
  default_outbound_access_enabled   = each.value.default_outbound_access_enabled
  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  dynamic "delegation" {
    for_each = lookup(each.value, "service_delegation", null) != null ? [each.value.service_delegation] : []
    content {
      name = "delegation"
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}

# ------------------------------------------------------------------------------------------------------
# Network Security Group
# ------------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.network_security_group
  name                = "nsg-${each.value.name}-${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = local.tags
}

resource "azurerm_network_security_rule" "nsg_rules" {
  # 配列をマップに変換
  for_each                     = { for rule in var.network_security_rule : format("%s-%s", rule.target_nsg, rule.name) => rule }
  resource_group_name          = azurerm_resource_group.rg.name
  network_security_group_name  = azurerm_network_security_group.nsg[each.value.target_nsg].name
  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = lookup(each.value, "source_port_range", null)
  source_port_ranges           = lookup(each.value, "source_port_ranges", null)
  destination_port_range       = lookup(each.value, "destination_port_range", null)
  destination_port_ranges      = lookup(each.value, "destination_port_ranges", null)
  source_address_prefix        = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes      = lookup(each.value, "source_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefix", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each                  = var.network_security_group
  subnet_id                 = azurerm_subnet.subnet[each.value.target_subnet].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

# ------------------------------------------------------------------------------------------------------
# Azure Key Vault
# ------------------------------------------------------------------------------------------------------
resource "azurerm_key_vault" "kv" {
  name                       = "kv-${var.environment_name}-${random_integer.num.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  sku_name                   = var.key_vault.sku_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization  = var.key_vault.enable_rbac_authorization
  purge_protection_enabled   = var.key_vault.purge_protection_enabled
  soft_delete_retention_days = var.key_vault.soft_delete_retention_days
  access_policy              = []

  network_acls {
    default_action             = var.key_vault.network_acls.default_action
    bypass                     = var.key_vault.network_acls.bypass
    ip_rules                   = var.allowed_cidr
    virtual_network_subnet_ids = var.key_vault.network_acls.virtual_network_subnet_ids
  }

  # GitHub Actions のランナーの IP アドレスを KeyVault のファイアウォールに追加するため IP アドレスの変更を無視する
  lifecycle {
    ignore_changes = [network_acls[0].ip_rules]
  }

  tags = local.tags
}

resource "azurerm_key_vault_secret" "COSMOSDB_PRIMARY_KEY" {
  name         = replace("COSMOSDB_PRIMARY_KEY", "_", "-")
  value        = azurerm_cosmosdb_account.account.primary_key
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "text/plain"
}

# ------------------------------------------------------------------------------------------------------
# Azure Cosmos DB
# ------------------------------------------------------------------------------------------------------
resource "azurerm_cosmosdb_account" "account" {
  name                          = "cosmos-${var.environment_name}-${random_integer.num.result}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  offer_type                    = var.cosmosdb_account.offer_type
  kind                          = var.cosmosdb_account.kind
  free_tier_enabled             = var.cosmosdb_account.free_tier_enabled
  public_network_access_enabled = var.cosmosdb_account.public_network_access_enabled
  ip_range_filter = concat(
    var.allowed_cidr,
    split(",", local.azure_portal_ips.cosmosdb)
  )

  consistency_policy {
    consistency_level       = var.cosmosdb_account.consistency_policy.consistency_level
    max_interval_in_seconds = var.cosmosdb_account.consistency_policy.max_interval_in_seconds
    max_staleness_prefix    = var.cosmosdb_account.consistency_policy.max_staleness_prefix
  }

  geo_location {
    location          = var.cosmosdb_account.geo_location.location
    failover_priority = var.cosmosdb_account.geo_location.failover_priority
    zone_redundant    = var.cosmosdb_account.geo_location.zone_redundant
  }

  capacity {
    total_throughput_limit = var.cosmosdb_account.capacity.total_throughput_limit
  }

  backup {
    type = var.cosmosdb_account.backup.type
    tier = var.cosmosdb_account.backup.tier
  }

  tags = local.tags
}

resource "azurerm_cosmosdb_sql_database" "database" {
  name                = var.cosmosdb_sql_database.name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.account.name

  dynamic "autoscale_settings" {
    for_each = var.cosmosdb_sql_database.autoscale_settings != null ? [true] : []

    content {
      max_throughput = var.cosmosdb_sql_database.autoscale_settings.max_throughput
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                  = var.cosmosdb_sql_container.name
  resource_group_name   = azurerm_resource_group.rg.name
  account_name          = azurerm_cosmosdb_account.account.name
  database_name         = azurerm_cosmosdb_sql_database.database.name
  partition_key_paths   = var.cosmosdb_sql_container.partition_key_paths
  partition_key_version = var.cosmosdb_sql_container.partition_key_version

  dynamic "autoscale_settings" {
    for_each = var.cosmosdb_sql_container.autoscale_settings != null ? [true] : []

    content {
      max_throughput = var.cosmosdb_sql_container.autoscale_settings.max_throughput
    }
  }
}

# ------------------------------------------------------------------------------------------------------
# Log Analytics Workspace
# ------------------------------------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "workspace" {
  name                       = "workspace-${var.environment_name}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  sku                        = var.log_analytics.sku
  retention_in_days          = var.log_analytics.retention_in_days
  internet_ingestion_enabled = var.log_analytics.internet_ingestion_enabled
  internet_query_enabled     = var.log_analytics.internet_query_enabled

  tags = local.tags
}

# ------------------------------------------------------------------------------------------------------
# Application Insights
# ------------------------------------------------------------------------------------------------------
resource "azurerm_application_insights" "appi" {
  name                       = "appi-${var.environment_name}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  workspace_id               = azurerm_log_analytics_workspace.workspace.id
  application_type           = var.application_insights.application_type
  retention_in_days          = var.application_insights.retention_in_days
  internet_ingestion_enabled = var.application_insights.internet_ingestion_enabled
  internet_query_enabled     = var.application_insights.internet_query_enabled

  tags = local.tags
}

# ------------------------------------------------------------------------------------------------------
# Private Endpoint
# ------------------------------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "zone" {
  for_each            = var.private_dns_zone
  name                = each.value
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  for_each              = var.private_dns_zone
  name                  = "vnetlink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.zone[each.key].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "pe" {
  for_each                      = local.private_endpoint
  name                          = "pe-${each.value.name}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  subnet_id                     = azurerm_subnet.subnet["pe"].id
  custom_network_interface_name = "pe-nic-${each.value.name}"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = each.value.private_dns_zone_ids
  }

  private_service_connection {
    name                           = "connection"
    is_manual_connection           = false
    private_connection_resource_id = each.value.private_connection_resource_id
    subresource_names              = each.value.subresource_names
  }

  tags = local.tags
}

# ------------------------------------------------------------------------------------------------------
# User Assigned Managed ID
# ------------------------------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "id" {
  name                = "id-${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = local.tags
}

resource "azurerm_role_assignment" "role" {
  for_each             = toset(var.role_assignment)
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.id.principal_id
}

# ------------------------------------------------------------------------------------------------------
# Container Registry
# ------------------------------------------------------------------------------------------------------
resource "azurerm_container_registry" "cr" {
  name                          = replace("cr-${var.environment_name}-${random_integer.num.result}", "-", "")
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = var.container_registry.sku_name
  admin_enabled                 = var.container_registry.admin_enabled
  public_network_access_enabled = var.container_registry.public_network_access_enabled
  zone_redundancy_enabled       = var.container_registry.zone_redundancy_enabled

  tags = local.tags
}

# ------------------------------------------------------------------------------------------------------
# Container App Environment
# ------------------------------------------------------------------------------------------------------
resource "azurerm_container_app_environment" "cae" {
  name                                        = "cae-${var.environment_name}"
  resource_group_name                         = azurerm_resource_group.rg.name
  infrastructure_resource_group_name          = "${azurerm_resource_group.rg.name}-cae"
  location                                    = azurerm_resource_group.rg.location
  zone_redundancy_enabled                     = var.container_app_environment.zone_redundancy_enabled
  infrastructure_subnet_id                    = azurerm_subnet.subnet[var.container_app_environment.target_subnet].id
  logs_destination                            = var.container_app_environment.logs_destination
  dapr_application_insights_connection_string = azurerm_application_insights.appi.connection_string

  workload_profile {
    name                  = var.container_app_environment.workload_profile.name
    workload_profile_type = var.container_app_environment.workload_profile.workload_profile_type
    minimum_count         = var.container_app_environment.workload_profile.minimum_count
    maximum_count         = var.container_app_environment.workload_profile.maximum_count
  }

  tags = local.tags
}

# azurerm_container_app_environment_dapr_component では SecretRef が使えないので azapi プロバイダーを使う
resource "azapi_resource" "dapr_components" {
  for_each  = local.dapr_components
  type      = "Microsoft.App/managedEnvironments/daprComponents@2025-01-01"
  name      = each.key
  parent_id = azurerm_container_app_environment.cae.id
  body = {
    properties = {
      componentType = each.value.component_type
      version       = each.value.version
      metadata = [
        for item in each.value.metadata : {
          name      = item.name
          value     = lookup(item, "value", null)
          secretRef = lookup(item, "secretRef", null)
        }
      ]
      secretStoreComponent = each.value.secretStoreComponent
    }
  }
}

# ------------------------------------------------------------------------------------------------------
# Container App
# ------------------------------------------------------------------------------------------------------
resource "azurerm_container_app" "ca" {
  for_each                     = var.container_app
  name                         = "ca-${each.value.name}"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  workload_profile_name        = one(azurerm_container_app_environment.cae.workload_profile).name
  revision_mode                = each.value.revision_mode

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.id.id
    ]
  }

  template {
    min_replicas = each.value.template.min_replicas
    max_replicas = each.value.template.max_replicas

    container {
      name = each.value.template.container.name
      # Initial container image (overwritten by CI/CD)
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = each.value.template.container.cpu
      memory = each.value.template.container.memory

      liveness_probe {
        transport               = each.value.template.container.liveness_probe.transport
        path                    = each.value.template.container.liveness_probe.path
        port                    = each.value.template.container.liveness_probe.port
        initial_delay           = each.value.template.container.liveness_probe.initial_delay
        interval_seconds        = each.value.template.container.liveness_probe.interval_seconds
        timeout                 = each.value.template.container.liveness_probe.timeout
        failure_count_threshold = each.value.template.container.liveness_probe.failure_count_threshold
      }

      dynamic "env" {
        for_each = lookup(local.container_app_env, each.key, {})
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    http_scale_rule {
      name                = each.value.template.http_scale_rule.name
      concurrent_requests = each.value.template.http_scale_rule.concurrent_requests
    }
  }

  ingress {
    external_enabled           = each.value.ingress.external_enabled
    allow_insecure_connections = each.value.ingress.allow_insecure_connections
    client_certificate_mode    = each.value.ingress.client_certificate_mode
    transport                  = each.value.ingress.transport
    target_port                = each.value.ingress.target_port

    dynamic "ip_security_restriction" {
      for_each = toset(var.allowed_cidr)
      content {
        name             = each.value.ingress.ip_security_restriction.name
        action           = each.value.ingress.ip_security_restriction.action
        ip_address_range = ip_security_restriction.value
      }
    }

    traffic_weight {
      latest_revision = each.value.ingress.traffic_weight.latest_revision
      percentage      = each.value.ingress.traffic_weight.percentage
    }
  }

  dynamic "dapr" {
    for_each = each.value.dapr != null ? [true] : []
    content {
      app_id       = each.value.dapr.app_id
      app_port     = each.value.dapr.app_port
      app_protocol = each.value.dapr.app_protocol
    }
  }

  registry {
    server   = azurerm_container_registry.cr.login_server
    identity = azurerm_user_assigned_identity.id.id
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
    ]
  }

  tags = merge(local.tags, { "azd-service-name" = each.key })
}

# ------------------------------------------------------------------------------------------------------
# NAT Gateway
# ------------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "pip" {
  name                = "ip-nat-${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.nat_gateway.public_ip.sku
  allocation_method   = var.nat_gateway.public_ip.allocation_method
  zones               = var.nat_gateway.public_ip.zones

  tags = local.tags
}

resource "azurerm_nat_gateway" "nat" {
  name                    = "nat-${var.environment_name}"
  resource_group_name     = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  sku_name                = var.nat_gateway.sku_name
  idle_timeout_in_minutes = var.nat_gateway.idle_timeout_in_minutes
  zones                   = var.nat_gateway.zones

  tags = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "pip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.pip.id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_association" {
  for_each       = toset(var.nat_gateway.target_subnets)
  subnet_id      = azurerm_subnet.subnet[each.value].id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

# ------------------------------------------------------------------------------------------------------
# 診断設定
# ------------------------------------------------------------------------------------------------------
data "azurerm_monitor_diagnostic_categories" "diag_categories" {
  for_each    = local.diagnostic_setting_target_resources
  resource_id = each.value
}

locals {
  providers_with_dedicated_log_type = [
    "Microsoft.DocumentDB",
    "Microsoft.Network/applicationGateways",
  ]
}

resource "azurerm_monitor_diagnostic_setting" "diag" {
  for_each                   = local.diagnostic_setting_target_resources
  name                       = replace("${each.key}-${var.environment_name}-diag-setting", "_", "-")
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  # 診断設定の対象リソースが、専用の Log Analytics テーブルを持つリソースタイプ (local.providers_with_dedicated_log_type リスト内の正規表現パターンに一致するか) を判定する
  # もし一致する場合 (リストの長さ > 0)、ログの送信先タイプとして "Dedicated" を設定し、リソースタイプ固有の専用テーブルにログを送信する
  # 一致しない場合は null を設定し、デフォルトで共通の AzureDiagnostics テーブルに送信されるようにする
  log_analytics_destination_type = length([for provider in local.providers_with_dedicated_log_type : provider if can(regex(provider, each.value))]) > 0 ? "Dedicated" : null

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.diag_categories[each.key].log_category_types

    content {
      category = enabled_log.value
    }
  }
}
