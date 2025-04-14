#!/bin/bash

SUBSCRIPTION_ID="86093bd5-474b-461b-ac98-eab43df6459b"
RESOURCE_GROUP="rg-dataplatform-stg"
LOCATION="FranceCentral"
ADF_NAME="df-dataplatform-nadara-stg"
DBX_NAME="databricks-workspace"

az account set --subscription "$SUBSCRIPTION_ID"

# Criar RG
az group create --name $RESOURCE_GROUP --location $LOCATION

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

