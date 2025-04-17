#!/bin/bash

SUBSCRIPTION_ID="86093bd5-474b-461b-ac98-eab43df6459b"
RESOURCE_GROUP="rg-dataplatform-stg"
VNET_NAME="vnet-dataplatform"
STORAGE_ACCOUNT="sadataplatformstg"
LOCATION="FranceCentral"
TAGS="context='All Nadara Group' Owner='IT Department' Application='Dataplatform'"
ADF_NAME="df-dataplatform-nadara-stg"
DBX_NAME="databricks-workspace"

az account set --subscription "$SUBSCRIPTION_ID"

# Criar RG
az group create --name $RESOURCE_GROUP --location $LOCATION

# Criar VNET (Pedro)
az network vnet create \
  --name $VNET_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION
  --address-prefixes 10.100.68.0/22 \
  --tags Environment=all $TAGS

# Criar Subnets (Pedro)
az network vnet subnet create \
  --name sn-stg-adf-purview
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.70.0/26

az network vnet subnet create \
  --name databricks-pub-stg
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.70.64/26

az network vnet subnet create \
  --name databricks-stg
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.70.128/26

az network vnet subnet create \
  --name sn-stg-cosmosdb-containers
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.70.192/26

az network vnet subnet create \
  --name sn-stg-monitor-logs
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.69.192/26

az network vnet subnet create \
  --name sn-stg-snowflake-pe
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.70.160/27

# Criar Storage Account (Pedro)
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource_group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --enable-hierarchical-namespace true
  --tags Environment=stg $TAGS

# Criar Data Lake Filesystems (Pedro)
az storage fs create \
  --account-name $STORAGE_ACCOUNT
  --name dls-stg
  --auth-mode login

az storage fs create \
  --account-name $STORAGE_ACCOUNT
  --name dls-landing-stg
  --auth-mode login

# Criar diretórios no Data Lake (Pedro)
az storage fs directory create \
  --account-name $STORAGE_ACCOUNT
  --name scada
  --file-system dls-stg
  --auth-mode login

az storage fs directory create \
  --account-name $STORAGE_ACCOUNT
  --name "scada/bronze"
  --file-system dls-stg
  --auth-mode login

az storage fs directory create \
  --account-name $STORAGE_ACCOUNT
  --name "scada/silver"
  --file-system dls-stg
  --auth-mode login

az storage fs directory create \
  --account-name $STORAGE_ACCOUNT
  --name "scada/gold"
  --file-system dls-stg
  --auth-mode login

az storage fs directory create \
  --account-name $STORAGE_ACCOUNT
  --name scada
  --file-system dls-landing-stg
  --auth-mode login

# Criar ADF
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./adf/template.json \
  --parameters @./adf/parameters.json

# Criar Databricks Workspace
az databricks workspace create \
  --resource-group $RESOURCE_GROUP \
  --name $DBX_NAME \
  --location $LOCATION \
  --sku standard

