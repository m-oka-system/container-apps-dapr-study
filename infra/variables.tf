variable "environment_name" {
  type = string
}

variable "location" {
  type = string
}

variable "allowed_cidr" {
  type = list(string)
}

variable "custom_domain_name" {
  type = string
}

variable "vnet" {
  type = object({
    address_space = list(string)
  })
  default = {
    address_space = ["10.10.0.0/16"]
  }
}

variable "subnet" {
  type = map(object({
    name                              = string
    address_prefixes                  = list(string)
    default_outbound_access_enabled   = bool
    private_endpoint_network_policies = string
    service_delegation = object({
      name    = string
      actions = list(string)
    })
  }))
  default = {
    pe = {
      name                              = "pe"
      address_prefixes                  = ["10.10.0.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Enabled"
      service_delegation                = null
    }
    app = {
      name                              = "app"
      address_prefixes                  = ["10.10.1.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation = {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    agw = {
      name                              = "agw"
      address_prefixes                  = ["10.10.2.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation                = null
    }
  }
}

variable "network_security_group" {
  type = map(object({
    name          = string
    target_subnet = string
  }))
  default = {
    pe = {
      name          = "pe"
      target_subnet = "pe"
    }
    app = {
      name          = "app"
      target_subnet = "app"
    }
    agw = {
      name          = "agw"
      target_subnet = "agw"
    }
  }
}

variable "network_security_rule" {
  type = list(object({
    target_nsg                   = string
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))

  # 単数・複数の排他的なパラメータはどちらか一方を指定する
  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.source_port_range != null && rule.source_port_ranges == null) ||
      (rule.source_port_range == null && rule.source_port_ranges != null)
    ])
    error_message = "送信元ポートは単数(source_port_range)または複数(source_port_ranges)のどちらか一方のみ指定してください。"
  }

  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.destination_port_range != null && rule.destination_port_ranges == null) ||
      (rule.destination_port_range == null && rule.destination_port_ranges != null)
    ])
    error_message = "宛先ポートは単数(destination_port_range)または複数(destination_port_ranges)のどちらか一方のみ指定してください。"
  }

  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.source_address_prefix != null && rule.source_address_prefixes == null) ||
      (rule.source_address_prefix == null && rule.source_address_prefixes != null)
    ])
    error_message = "送信元アドレスは単数(source_address_prefix)または複数(source_address_prefixes)のどちらか一方のみ指定してください。"
  }

  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.destination_address_prefix != null && rule.destination_address_prefixes == null) ||
      (rule.destination_address_prefix == null && rule.destination_address_prefixes != null)
    ])
    error_message = "宛先アドレスは単数(destination_address_prefix)または複数(destination_address_prefixes)のどちらか一方のみ指定してください。"
  }

  default = [
    # PE Subnet
    {
      target_nsg                 = "pe"
      name                       = "AllowAppSubnetHTTPSInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "pe"
      name                       = "AllowAgwSubnetHTTPSInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.2.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "pe"
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "pe"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # Application Gateway Subnet
    {
      target_nsg                 = "agw"
      name                       = "AllowGatewayManagerInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "agw"
      name                       = "AllowAzureLoadBalancerInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "agw"
      name                       = "AllowHTTPSInbound"
      priority                   = 1200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "agw"
      name                       = "AllowHTTPInbound"
      priority                   = 1300
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "agw"
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # App Subnet
    {
      target_nsg                 = "app"
      name                       = "AllowPeSubnetHTTPSOutbound"
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "10.10.0.0/24"
    },
    {
      target_nsg                 = "app"
      name                       = "AllowMicrosoftContainerRegistryOutbound"
      priority                   = 1100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "MicrosoftContainerRegistry"
    },
    {
      target_nsg                 = "app"
      name                       = "AllowAzureFrontDoorOutbound"
      priority                   = 1200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "AzureFrontDoor.FirstParty"
    },
    {
      target_nsg                 = "app"
      name                       = "AllowAzureActiveDirectoryOutbound"
      priority                   = 1300
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "AzureActiveDirectory"
    },
    {
      target_nsg                 = "app"
      name                       = "AllowAzureMonitorOutbound"
      priority                   = 1400
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "AzureMonitor"
    },
    {
      target_nsg                 = "app"
      name                       = "AllowAzureContainerRegistryOutbound"
      priority                   = 1500
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "AzureContainerRegistry.JapanEast"
    },
    {
      target_nsg                 = "app"
      name                       = "AllowStorageOutbound"
      priority                   = 1600
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "Storage.JapanEast"
    },
    {
      target_nsg                 = "app"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]
}

variable "key_vault" {
  type = object({
    sku_name                      = string
    enable_rbac_authorization     = bool
    purge_protection_enabled      = bool
    soft_delete_retention_days    = number
    public_network_access_enabled = bool
    network_acls = object({
      default_action             = string
      bypass                     = string
      virtual_network_subnet_ids = list(string)
    })
  })
  default = {
    sku_name                      = "standard"
    enable_rbac_authorization     = true
    purge_protection_enabled      = false
    soft_delete_retention_days    = 7
    public_network_access_enabled = true
    network_acls = {
      default_action             = "Deny"
      bypass                     = "AzureServices"
      virtual_network_subnet_ids = []
    }
  }
}

variable "cosmosdb_account" {
  type = object({
    offer_type                    = string
    kind                          = string
    free_tier_enabled             = bool
    public_network_access_enabled = bool
    consistency_policy = object({
      consistency_level       = string
      max_interval_in_seconds = number
      max_staleness_prefix    = number
    })
    geo_location = object({
      location          = string
      failover_priority = number
      zone_redundant    = bool
    })
    capacity = object({
      total_throughput_limit = number
    })
    backup = object({
      type = string
      tier = string
    })
  })
  default = {
    offer_type                    = "Standard"
    kind                          = "GlobalDocumentDB"
    free_tier_enabled             = false
    public_network_access_enabled = true
    consistency_policy = {
      consistency_level       = "Session"
      max_interval_in_seconds = 5
      max_staleness_prefix    = 100
    }
    geo_location = {
      location          = "japaneast"
      failover_priority = 0
      zone_redundant    = false
    }
    capacity = {
      total_throughput_limit = 1000
    }
    backup = {
      type = "Continuous"
      tier = "Continuous7Days"
    }
  }
}

variable "cosmosdb_sql_database" {
  type = object({
    name = string
    autoscale_settings = object({
      max_throughput = number
    })
  })
  default = {
    name = "database1"
    autoscale_settings = {
      max_throughput = 1000
    }
  }
}

variable "cosmosdb_sql_container" {
  type = object({
    name                  = string
    partition_key_paths   = list(string)
    partition_key_version = number
    autoscale_settings = object({
      max_throughput = number
    })
  })
  default = {
    name                  = "container1"
    partition_key_paths   = ["/id"]
    partition_key_version = 2
    autoscale_settings    = null
  }
}

variable "private_dns_zone" {
  type = map(string)
  default = {
    kv     = "privatelink.vaultcore.azure.net"
    cosmos = "privatelink.documents.azure.com"
  }
}

variable "log_analytics" {
  type = object({
    sku                        = string
    retention_in_days          = number
    internet_ingestion_enabled = bool
    internet_query_enabled     = bool
  })
  default = {
    sku                        = "PerGB2018"
    retention_in_days          = 30
    internet_ingestion_enabled = false
    internet_query_enabled     = true
  }
}

variable "application_insights" {
  type = object({
    name                       = string
    application_type           = string
    retention_in_days          = number
    internet_ingestion_enabled = bool
    internet_query_enabled     = bool
  })
  default = {
    name                       = "app"
    application_type           = "web"
    retention_in_days          = 90
    internet_ingestion_enabled = false
    internet_query_enabled     = true
  }
}

variable "user_assigned_identity" {
  type = map(object({
    name = string
  }))
  default = {
    ca = {
      name = "ca"
    }
    agw = {
      name = "agw"
    }
  }
}

variable "role_assignment" {
  type = map(object({
    target_identity      = string
    role_definition_name = string
  }))
  default = {
    ca_acr_pull = {
      target_identity      = "ca"
      role_definition_name = "AcrPull"
    }
    ca_key_vault_secrets_user = {
      target_identity      = "ca"
      role_definition_name = "Key Vault Secrets User"
    }
    agw_key_vault_secrets_user = {
      target_identity      = "agw"
      role_definition_name = "Key Vault Secrets User"
    }
  }
}

variable "application_gateway" {
  type = object({
    enable_http2                      = bool
    fips_enabled                      = bool
    force_firewall_policy_association = bool
    target_user_assigned_identity     = string
    zones                             = list(string)
    sku = object({
      name     = string
      tier     = string
      capacity = number
    })
    public_ip = object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    })
  })
  default = {
    enable_http2                      = true
    fips_enabled                      = false
    force_firewall_policy_association = false
    target_user_assigned_identity     = "agw"
    zones                             = ["1", "2", "3"]
    sku = {
      name     = "Basic"
      tier     = "Basic"
      capacity = 1
    }
    public_ip = {
      sku               = "Standard"
      allocation_method = "Static"
      zones             = ["1", "2", "3"]
    }
  }
}

variable "container_registry" {
  type = object({
    sku_name                      = string
    admin_enabled                 = bool
    public_network_access_enabled = bool
    zone_redundancy_enabled       = bool
  })
  default = {
    sku_name                      = "Basic"
    admin_enabled                 = false
    public_network_access_enabled = true
    zone_redundancy_enabled       = false
  }
}

variable "container_app_environment" {
  type = object({
    zone_redundancy_enabled        = bool
    logs_destination               = string
    target_subnet                  = string
    internal_load_balancer_enabled = bool
    workload_profile = object({
      name                  = string
      workload_profile_type = string
      minimum_count         = number
      maximum_count         = number
    })
  })
  default = {
    zone_redundancy_enabled        = true
    logs_destination               = "azure-monitor"
    target_subnet                  = "app"
    internal_load_balancer_enabled = true
    workload_profile = {
      name                  = "Consumption"
      workload_profile_type = "Consumption"
      # Consumption の場合は 0 にする
      minimum_count = 0
      maximum_count = 0
    }
  }
}

variable "container_app" {
  type = map(object({
    name          = string
    revision_mode = string
    template = object({
      min_replicas = number
      max_replicas = number
      container = object({
        name   = string
        cpu    = number
        memory = string
        liveness_probe = object({
          transport               = string
          path                    = string
          port                    = number
          initial_delay           = number
          interval_seconds        = number
          timeout                 = number
          failure_count_threshold = number
        })
      })
      http_scale_rule = object({
        name                = string
        concurrent_requests = number
      })
    })
    ingress = object({
      external_enabled           = bool
      allow_insecure_connections = bool
      client_certificate_mode    = string
      transport                  = string
      target_port                = number
      ip_security_restriction = object({
        name   = string
        action = string
      })
      traffic_weight = object({
        latest_revision = bool
        percentage      = number
      })
    })
    dapr = object({
      app_id       = string
      app_port     = number
      app_protocol = string
    })
  }))
  default = {
    frontend = {
      name          = "frontend"
      revision_mode = "Single"
      template = {
        min_replicas = 1
        max_replicas = 10
        container = {
          name   = "frontend"
          cpu    = 0.25
          memory = "0.5Gi"
          liveness_probe = {
            transport               = "HTTP"
            path                    = "/healthz"
            port                    = 3000
            initial_delay           = 1
            interval_seconds        = 10
            timeout                 = 1
            failure_count_threshold = 3
          }
        }
        http_scale_rule = {
          name                = "http-scale"
          concurrent_requests = 100
        }
      }
      ingress = {
        external_enabled           = true
        allow_insecure_connections = false
        client_certificate_mode    = "ignore"
        transport                  = "auto"
        target_port                = 3000
        ip_security_restriction    = null
        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
      dapr = null
    }
    backend = {
      name          = "backend"
      revision_mode = "Single"
      template = {
        min_replicas = 1
        max_replicas = 10
        container = {
          name   = "backend"
          cpu    = 0.25
          memory = "0.5Gi"
          liveness_probe = {
            transport               = "HTTP"
            path                    = "/healthz"
            port                    = 5002
            initial_delay           = 1
            interval_seconds        = 10
            timeout                 = 1
            failure_count_threshold = 3
          }
        }
        http_scale_rule = {
          name                = "http-scale"
          concurrent_requests = 100
        }
      }
      ingress = {
        external_enabled           = false
        allow_insecure_connections = false
        client_certificate_mode    = "ignore"
        transport                  = "auto"
        target_port                = 5002
        ip_security_restriction    = null
        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
      dapr = {
        app_id       = "product-api"
        app_port     = 5002
        app_protocol = "http"
      }
    }
  }
}

variable "nat_gateway" {
  type = object({
    target_subnets          = list(string)
    sku_name                = string
    idle_timeout_in_minutes = number
    zones                   = list(string)
    public_ip = object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    })
  })
  default = {
    target_subnets          = ["app"]
    sku_name                = "Standard"
    idle_timeout_in_minutes = 4
    zones                   = ["1"]
    public_ip = {
      sku               = "Standard"
      allocation_method = "Static"
      zones             = ["1"]
    }
  }
}
