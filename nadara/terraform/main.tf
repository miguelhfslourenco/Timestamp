terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      #version = ">=3.0.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      #version = ">=0.2.0"
    }
  }

  #required_version = ">=1.0.0"
}

provider "azurerm" {
  features {}
  subscription_id = "86093bd5-474b-461b-ac98-eab43df6459b"
  resource_provider_registrations = "none"
}

#####################
## Resource Groups ##
#####################
resource "azurerm_resource_group" "rg-dataplatform_extra" {
  name     = "rg-dataplatform_extra"
  location = "France Central"
  tags     = merge(var.common_tags, {"Environment" = "all"})
}

resource "azurerm_resource_group" "rg-dataplatform-dev" {
  name     = "rg-dataplatform-dev"
  location = "France Central"
  tags     = merge(var.common_tags, {"Environment" = "dev"})
}
/*
resource "azurerm_resource_group" "stg" {
  name     = "rg-dataplatform-stg"
  location = "France Central"
  tags     = merge(var.common_tags, {"Environment" = "stg"})
}

resource "azurerm_resource_group" "prod" {
  name     = "rg-dataplatform-prd"
  location = "France Central"
  tags     = merge(var.common_tags, {"Environment" = "prd"})
}
*/

#############
## Network ##
#############
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dataplatform"
  location            = azurerm_resource_group.rg-dataplatform_extra.location
  resource_group_name = azurerm_resource_group.rg-dataplatform_extra.name
  address_space       = ["10.100.68.0/22"]
  tags                = merge(var.common_tags, {"Environment" = "all"})
}

locals {
  subnets = [
  #DEV
    { name = "sn-dev-adf-purview", cidr = "10.100.68.0/26" },
    { name = "databricks-pub-dev", cidr = "10.100.68.64/26" }, 
    { name = "databricks-dev", cidr = "10.100.68.128/25" }, 
    { name = "sn-dev-cosmosdb-containers", cidr = "10.100.69.0/26" }, 
    { name = "sn-dev-monitor-logs", cidr = "10.100.69.64/26" }, 
    { name = "sn-dev-snowflake-pe", cidr = "10.100.69.128/27" },
  /*
  #STG
    { name = "sn-stg-adf-purview", cidr = "10.100.70.0/26" },
    { name = "databricks-pub-stg", cidr = "10.100.70.64/26" }, 
    { name = "databricks-stg", cidr = "10.100.70.128/26" }, 
    { name = "sn-stg-cosmosdb-containers", cidr = "10.100.70.192/26" },
    { name = "sn-stg-monitor-logs", cidr = "10.100.69.192/26" },
    { name = "sn-stg-snowflake-pe", cidr = "10.100.70.160/27" },
  #PRD
    { name = "sn-prod-adf-purview", cidr = "10.100.71.0/26" },
    { name = "databricks-pub-prod", cidr = "10.100.71.64/26" }, 
    { name = "databricks-prod", cidr = "10.100.71.128/25" }, 
    { name = "sn-prod-cosmosdb-containers", cidr = "10.100.70.0/26" },
    { name = "sn-prod-monitor-logs", cidr = "10.100.68.192/26" },
    { name = "sn-prod-snowflake-pe", cidr = "10.100.70.64/27" },
  */
  ]
}

resource "azurerm_subnet" "subnets" {
  for_each             = { for subnet in local.subnets : subnet.name => subnet }
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg-dataplatform_extra.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.cidr]
}

#resource "azurerm_network_security_group" "nsg_dev" {
#  name                = "nsg-dev"
#  location            = azurerm_resource_group.rg-dataplatform_extra.location
#  resource_group_name = azurerm_resource_group.rg-dataplatform_extra.name
#
#  security_rule {
#    name                       = "Allow-Dev-Internal"
#    priority                   = 100
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "*"
#    source_address_prefix      = "10.100.68.0/22"
#    destination_address_prefix = "10.100.68.0/22"
#    source_port_range          = "*"
#    destination_port_range     = "*"
#  }
#}

/*
resource "azurerm_subnet" "sn-dev-adf-purview" {
  name                 = "sn-dev-adf-purview"
  resource_group_name  = azurerm_resource_group.rg-dataplatform_extra.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.100.68.0/26"]
}

resource "azurerm_subnet" "sn-dev-storage-keyvault" {
  name                 = "sn-dev-storage-keyvault"
  resource_group_name  = azurerm_resource_group.rg-dataplatform_extra.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.100.68.64/26"]
}

resource "azurerm_subnet" "sn-dev-databricks" {
  name                 = "sn-dev-databricks"
  resource_group_name  = azurerm_resource_group.rg-dataplatform_extra.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.100.68.128/25"]
}

resource "azurerm_subnet" "sn-dev-cosmosdb-containers" {
  name                 = "sn-dev-cosmosdb-containers"
  resource_group_name  = azurerm_resource_group.rg-dataplatform_extra.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.100.69.0/26"]
}

resource "azurerm_subnet" "sn-dev-monitor-logs" {
  name                 = "sn-dev-monitor-logs"
  resource_group_name  = azurerm_resource_group.rg-dataplatform_extra.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.100.69.64/26"]
}
*/

#resource "azurerm_network_security_group" "nsg" {
#  name                = "nsg-dataplatform"
#  location            = azurerm_resource_group.rg-dataplatform_extra.location
#  resource_group_name = azurerm_resource_group.rg-dataplatform_extra.name
#  tags                = merge(var.common_tags, {"Environment" = "all"})
#}

#resource "azurerm_virtual_network_gateway" "express_route" {
#  name                = "express-route-gateway"
#  location            = azurerm_resource_group.rg-dataplatform_extra.location
#  resource_group_name = azurerm_resource_group.rg-dataplatform_extra.name
#  type                = "ExpressRoute"
#  vpn_type            = "RouteBased"
#  tags                = merge(var.common_tags, {"Environment" = "all"})
#}

######################
## Storage Account / Key Vaults ###
######################
resource "azurerm_storage_account" "storage_nadara" {
  name                            = "sadataplatfnadara"
  resource_group_name             = azurerm_resource_group.rg-dataplatform_extra.name
  location                        = azurerm_resource_group.rg-dataplatform_extra.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  is_hns_enabled                  = true
  tags                            = merge(var.common_tags, {"Environment" = "dev"})
}


#resource "azurerm_storage_account" "storage_stg" {
#  name                     = "sadataplatformstg"
#  resource_group_name      = azurerm_resource_group.rg-dataplatform-stg.name
#  location                 = azurerm_resource_group.rg-dataplatform-stg.location
#  account_tier             = "Standard"
#  account_replication_type = "LRS"
#  is_hns_enabled           = true
#  tags                     = merge(var.common_tags, {"Environment" = "stg"})
#}

#resource "azurerm_storage_account" "storage_prd" {
#  name                     = "sadataplatformprd"
#  resource_group_name      = azurerm_resource_group.rg-dataplatform-prd.name
#  location                 = azurerm_resource_group.rg-dataplatform-prd.location
#  account_tier             = "Standard"
#  account_replication_type = "LRS"
#  is_hns_enabled           = true
#  tags                     = merge(var.common_tags, {"Environment" = "prd"})
#}

#Snowflake

##################
## Development ###
##################
resource "azurerm_storage_data_lake_gen2_filesystem" "datalake_dev" {
  name               = "dls-dev"
  storage_account_id = azurerm_storage_account.storage_nadara.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "datalake_landing" {
  name               = "dls-landing"
  storage_account_id = azurerm_storage_account.storage_nadara.id
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv_dev" {
  name                       = "kv-nadara-dev"
  location                   = azurerm_resource_group.rg-dataplatform-dev.location
  resource_group_name        = azurerm_resource_group.rg-dataplatform-dev.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = false
}


#resource "azurerm_storage_data_lake_gen2_filesystem" "datalake_stg" {
#  name               = "dls-stg"
#  storage_account_id = azurerm_storage_account.storage_stg.id
#}

#resource "azurerm_storage_data_lake_gen2_filesystem" "datalake_prod" {
#  name               = "dls-prd"
#  storage_account_id = azurerm_storage_account.storage_prd.id
#}

#Will require two linked services
resource "azurerm_data_factory" "df-dataplatform-dev" {
  name                    = "df-dataplatform-nadara-dev"
  location                = azurerm_resource_group.rg-dataplatform-dev.location
  resource_group_name     = azurerm_resource_group.rg-dataplatform-dev.name
  #public_network_enabled  = false
  tags                    = merge(var.common_tags, {"Environment" = "dev"})
  global_parameter {
        name  = "environment"
        type  = "String"
        value = "dev"
    }
  identity { type = "SystemAssigned" }
}

#Linked Services
##PostgreSQL
###resource "azurerm_data_factory_linked_service_postgresqlv2" "ls_dev_postgresql" {
###  name            = "ls_dev_postgresql"
###  data_factory_id = azurerm_data_factory.df-dataplatform-dev.id
###  integration_runtime_name = "SHIR"
###  connection_string = "host=10.100.22.182;port=5432;database=hub;username=timestamp_reader;sslMode=Preferred;Password=@Microsoft.KeyVault(SecretName=key-df-ls-postgresql;VaultName=kv-nadara-dev)"
###}

###resource "azurerm_data_factory_linked_service_key_vault" "df_ls_keyvault" {
###  name            = "df-ls-keyvault"
###  data_factory_id = azurerm_data_factory.df-dataplatform-dev.id
###  key_vault_id    = azurerm_key_vault.kv_dev.id
###}

##Databricks##
###resource "azurerm_databricks_workspace" "databricks_dev" {
###  name                = "databricks-scada"
###  location            = azurerm_resource_group.rg-dataplatform-dev.location
###  resource_group_name = azurerm_resource_group.rg-dataplatform-dev.name
###  sku                 = "standard"
###  managed_resource_group_name = "rg-dataplatform_databricks-dev"
####  customer_managed_key {
####    key_vault_id = azurerm_key_vault.kv_dev.id
####    key_name     = "kv-databricks-dev"
####    key_version  = "<versao-da-chave>" #???
####  }
###  # Não permitir acesso público ao workspace
###  public_network_access_enabled = false
###}
###
###resource "azurerm_databricks_workspace" "databricks_dev" {
###  name                          = "databricks-scada"
###  location                      = azurerm_resource_group.rg-dataplatform-dev.location
###  resource_group_name           = azurerm_resource_group.rg-dataplatform-dev.name
###  sku                           = "standard"
###  managed_resource_group_name   = "rg-dataplatform_databricks-dev"
###  public_network_access_enabled = false
###  network_security_group_rules_required = "AllRules"
###  tags                = merge(var.common_tags, {"Environment" = "dev"})
###  custom_parameters {
###      virtual_network_id     = azurerm_virtual_network.vnet.id
###      private_subnet_name    = azurerm_subnet.subnets["sn-dev-databricks"].name
###      public_subnet_name    = azurerm_subnet.subnets["sn-dev-databricks"].name
###      storage_account_name   = azurerm_storage_account.storage_nadara.name
###      public_subnet_network_security_group_association_id = 
###      private_subnet_network_security_group_association_id =
###      storage_account_sku_name = "Standard_LRS"
###    }
###}

#Private Endpoint for Databricks
#resource "azurerm_private_endpoint" "databricks_pe" {
#  name                = "databricks-private-endpoint"
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name
#  subnet_id           = azurerm_subnet.private_subnet.id
#
#  private_service_connection {
#    name                           = "databricks-private-link"
#    private_connection_resource_id = azurerm_databricks_workspace.databricks.id
#    subresource_names              = ["databricks_ui_api"]
#    is_manual_connection           = false
#  }
#}

#############
## MLCube ###
#############
#resource "azurerm_container_group" "container" {
#  name                = "container-group-dataplatform"
#  location            = azurerm_resource_group.rg-dataplatform-dev.location
#  resource_group_name = azurerm_resource_group.rg-dataplatform-dev.name
#  os_type             = "Linux"
#  container {
#    name   = "app-container"
#    image  = "nginx:latest"
#    cpu    = "0.5"
#    memory = "1.5"
#    tags = var.common_tags
#}
#  tags = var.common_tags
#}

#resource "azurerm_cosmosdb_account" "cosmos" {
#  name                = "cosmosdb-dataplatform"
#  location            = azurerm_resource_group.rg-dataplatform-dev.location
#  resource_group_name = azurerm_resource_group.rg-dataplatform-dev.name
#  offer_type          = "Standard"
#  kind                = "GlobalDocumentDB"
#  consistency_policy {
#    consistency_level = "Session"
#    tags = var.common_tags
#}
#  tags = var.common_tags
#}

################
## Log/Audit ###
################

#resource "azurerm_purview_account" "purview" {
#  name                = "purview-dataplatform"
#  location            = azurerm_resource_group.rg-dataplatform-dev.location
#  resource_group_name = azurerm_resource_group.rg-dataplatform-dev.name
#  sku                 = "Standard"
#  tags = var.common_tags
#}

#resource "azurerm_log_analytics_workspace" "log" {
#  name                = "log-analytics-dataplatform"
#  location            = azurerm_resource_group.rg-dataplatform-dev.location
#  resource_group_name = azurerm_resource_group.rg-dataplatform-dev.name
#  sku                 = "PerGB2018"
#  tags = var.common_tags
#}

#resource "azurerm_monitor_diagnostic_setting" "monitor" {
#  name                       = "monitoring"
#  target_resource_id         = azurerm_resource_group.rg-dataplatform-dev.id
#  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id
#  tags = var.common_tags
#}
