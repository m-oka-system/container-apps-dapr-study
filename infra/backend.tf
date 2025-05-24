terraform {
  backend "azurerm" {
    # azd を使用する場合は provider.conf.json に設定する
    resource_group_name  = rg-terraform-state
    storage_account_name = stterraformstate84503
    container_name       = terraform-state
    key                  = dev.terraform.tfstate
    use_azuread_auth     = true
  }
}
