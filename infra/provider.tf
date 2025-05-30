terraform {
  required_version = "~> 1.11"
  required_providers {
    azurerm = {
      version = "~>4.0"
      source  = "hashicorp/azurerm"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.4"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "azurerm" {
  # リソースプロバイダーの自動登録を無効にする
  resource_provider_registrations = "none"

  # リソースプロバイダーの登録を手動で行う
  resource_providers_to_register = [
    "Microsoft.Advisor",
    "Microsoft.App",
    "Microsoft.ContainerRegistry",
    "Microsoft.DocumentDB",
    "Microsoft.KeyVault",
    "Microsoft.Network",
  ]
  features {
    key_vault {
      # Azure Key Vault の論理削除を無効にする
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      # リソースグループ内にリソースがあっても削除する
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {
  enable_preflight = true
}

provider "azuread" {
  # Use the same tenant as azurerm
}
