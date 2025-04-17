#!/bin/bash

SUBSCRIPTION_ID="86093bd5-474b-461b-ac98-eab43df6459b"
RESOURCE_GROUP="rg-dataplatform-prd"
VNET_NAME="vnet-dataplatform"
STORAGE_ACCOUNT="sadataplatformprd"
LOCATION="FranceCentral"
TAGS="context='All Nadara Group' Owner='IT Department' Application='Dataplatform'"
ADF_NAME="df-dataplatform-nadara-prd"
DBX_NAME="databricks-workspace"

az account set --subscription "$SUBSCRIPTION_ID"

# Criar RG
az group create --name $RESOURCE_GROUP --location $LOCATION

# Criar VNET (Pedro) - Vnet foi criada pela equipa de infra da Nadara
#az network vnet create \
#  --name $VNET_NAME \
#  --resource-group $RESOURCE_GROUP \
#  --location $LOCATION
#  --address-prefixes 10.100.68.0/22 \
#  --tags Environment=all $TAGS

# Criar Subnets (Pedro)
az network vnet subnet create \
  --name sn-prod-adf-purview
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.71.0/26

az network vnet subnet create \
  --name databricks-pub-prod
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.71.64/26

az network vnet subnet create \
  --name databricks-prod
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.71.128/25

az network vnet subnet create \
  --name sn-prod-cosmosdb-containers
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.70.0/26

az network vnet subnet create \
  --name sn-prod-monitor-logs
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.68.192/26

az network vnet subnet create \
  --name sn-stg-snowflake-pe
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes 10.100.70.64/27

## Criar Storage Account (Pedro) - Criado pela equipa de infra da Nadara, apenas vamos criar os containers
#az storage account create \
#  --name $STORAGE_ACCOUNT \
#  --resource_group $RESOURCE_GROUP \
#  --location $LOCATION \
#  --sku Standard_LRS \
#  --kind StorageV2 \
#  --enable-hierarchical-namespace true
#  --tags Environment=prd $TAGS

# Criar Data Lake Filesystems (Pedro)
az storage fs create \
  --account-name $STORAGE_ACCOUNT
  --name dls-prd
  --auth-mode login

az storage fs create \
  --account-name $STORAGE_ACCOUNT
  --name dls-landing-prd
  --auth-mode login

# Criar diretórios no Data Lake (Pedro)
az storage fs directory create \
  --account-name $STORAGE_ACCOUNT
  --name scada
  --file-system dls-prd
  --auth-mode login

az storage fs directory create \
  --account-name $STORAGE_ACCOUNT
  --name "scada/bronze"
  --file-system dls-prd
  --auth-mode login

az storage fs directory create \
  --account-name $STORAGE_ACCOUNT
  --name "scada/silver"
  --file-system dls-prd
  --auth-mode login

az storage fs directory create \
  --account-name $STORAGE_ACCOUNT
  --name "scada/gold"
  --file-system dls-prd
  --auth-mode login

az storage fs directory create \
  --account-name $STORAGE_ACCOUNT
  --name scada
  --file-system dls-landing-prd
  --auth-mode login

# Criar key vault
az keyvault create \
  --name kv-nadara-prd \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku standard \
  --retention-days 90 \
  --enable-purge-protection false \
  --tags Environment=prd $TAGS

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
