###DEV
resource "azurerm_storage_data_lake_gen2_path" "sa_scada_folder" {
  path                   = "scada"
  storage_account_id     = azurerm_storage_account.storage_nadara.id
  filesystem_name        = azurerm_storage_data_lake_gen2_filesystem.datalake_dev.name
  resource               = "directory"
  #depends_on             = [azurerm_storage_data_lake_gen2_path.sa_scada_folder]
}

resource "azurerm_storage_data_lake_gen2_path" "sa_scada_bronze" {
  path                   = "scada/bronze"
  storage_account_id     = azurerm_storage_account.storage_nadara.id
  filesystem_name        = azurerm_storage_data_lake_gen2_filesystem.datalake_dev.name
  resource               = "directory"
  depends_on             = [azurerm_storage_data_lake_gen2_path.sa_scada_folder]
}

resource "azurerm_storage_data_lake_gen2_path" "sa_scada_silver" {
  path                   = "scada/silver"
  storage_account_id     = azurerm_storage_account.storage_nadara.id
  filesystem_name        = azurerm_storage_data_lake_gen2_filesystem.datalake_dev.name
  resource               = "directory"
  depends_on             = [azurerm_storage_data_lake_gen2_path.sa_scada_folder]
}

resource "azurerm_storage_data_lake_gen2_path" "sa_scada_gold" {
  path                   = "scada/gold"
  storage_account_id     = azurerm_storage_account.storage_nadara.id
  filesystem_name        = azurerm_storage_data_lake_gen2_filesystem.datalake_dev.name
  resource               = "directory"
  depends_on             = [azurerm_storage_data_lake_gen2_path.sa_scada_folder]
}

##datalake_landing
resource "azurerm_storage_data_lake_gen2_path" "sa_landing_scada" {
  path                   = "scada"
  storage_account_id     = azurerm_storage_account.storage_nadara.id
  filesystem_name        = azurerm_storage_data_lake_gen2_filesystem.datalake_landing.name
  resource               = "directory"
  #depends_on             = [azurerm_storage_data_lake_gen2_path.sa_scada_folder]
}
/*
###STG
resource "azurerm_storage_container" "sa_stg_container" {
  name                  = "stg"
  storage_account_id    = azurerm_storage_account.storage_nadara.id
  container_access_type = "private"

  tags                  = merge(var.common_tags, {"Environment" = "stg"})
}


###PRD
resource "azurerm_storage_container" "sa_prd_container" {
  name                  = "prd"
  storage_account_id    = azurerm_storage_account.storage_nadara.id
  container_access_type = "private"

  tags                  = merge(var.common_tags, {"Environment" = "prd"})
}
*/