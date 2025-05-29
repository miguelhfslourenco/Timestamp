#!/bin/bash

SUBSCRIPTION_ID="86093bd5-474b-461b-ac98-eab43df6459b"
RESOURCE_GROUP="rg-dataplatform-prd"
RESOURCE_GROUP_EXTRA="rg-dataplatform_extra"
MANAGED_RG="rg-dataplatform-databricks-prd"
VNET_NAME="vnet-dataplatform"
SUBNET_PUBLIC_NAME="databricks-pub-prd"
SUBNET_PRIVATE_NAME="databricks-prd"
SUBNET_PUBLIC_PREFIX="10.100.71.64/26"
SUBNET_PRIVATE_PREFIX="10.100.71.128/25"
STORAGE_ACCOUNT="sadataplatformprd"
LOCATION="francecentral"
TAGS="context='All Nadara Group' Owner='IT Department' Application='Dataplatform'"
ADF_NAME="df-dataplatform-nadara-prd"
DBX_NAME="databricks-workspace"
WORKSPACE_NAME="dbs-dp-prd"
NSG_NAME="nsg-databricks-prd"


az account set --subscription "$SUBSCRIPTION_ID"

# Criar RG
az group create --name $RESOURCE_GROUP --location $LOCATION

# Keyvault secrets
az keyvault secret set --vault-name kv-dp-nadara-prd --name DP-ELT --value Nadaradev@2025 --description "Snowflake Prod ELT Service User" --tags Environment=prd Project=DataPlatform Department="Digital & IT"
az keyvault secret set --vault-name kv-dp-nadara-prd --name key-df-ls-postgresql --value 'a,~"9mkOKqv2u}+)' --tags Environment=prd Project=DataPlatform Department="Digital & IT"
az keyvault secret set --vault-name kv-dp-nadara-prd --name shir-dev-password --value Timestamp_2025 --tags Environment=prd Project=DataPlatform Department="Digital & IT"
az keyvault secret set --vault-name kv-dp-nadara-prd --name key-adls --value $(az storage account keys list --resource-group rg-dataplatform_extra --account-name sadataplatfnadara --query [0].value -o tsv) --tags Environment=prd Project=DataPlatform Department="Digital & IT"

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

# Databricks
##Create subnets for Databricks
az network vnet subnet create --resource-group $RESOURCE_GROUP_EXTRA --vnet-name $VNET_NAME --name $SUBNET_PUBLIC_NAME --address-prefix $SUBNET_PUBLIC_PREFIX
az network vnet subnet create --resource-group $RESOURCE_GROUP_EXTRA --vnet-name $VNET_NAME --name $SUBNET_PRIVATE_NAME --address-prefix $SUBNET_PRIVATE_PREFIX

##Delegate subnets for Databricks
az network vnet subnet update --resource-group $RESOURCE_GROUP_EXTRA --vnet-name $VNET_NAME --name $SUBNET_PUBLIC_NAME --delegations Microsoft.Databricks/workspaces
az network vnet subnet update --resource-group $RESOURCE_GROUP_EXTRA --vnet-name $VNET_NAME --name $SUBNET_PRIVATE_NAME --delegations Microsoft.Databricks/workspaces

##Create NSG
az network nsg create --resource-group $RESOURCE_GROUP --name $NSG_NAME --location $LOCATION --tags Environment=prd Project=Dataplatform Department="Digital & IT"
NSG_ID=$(az resource list --name $NSG_NAME --query [].id -o tsv)

##Associate de NSG with the Subnets
az network vnet subnet update --resource-group $RESOURCE_GROUP_EXTRA --vnet-name $VNET_NAME --name $SUBNET_PUBLIC_NAME --network-security-group $NSG_ID
az network vnet subnet update --resource-group $RESOURCE_GROUP_EXTRA --vnet-name $VNET_NAME --name $SUBNET_PRIVATE_NAME --network-security-group $NSG_ID

##Create NSG Rules
###Inbound
az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "Allow-Databricks-Inbound" --priority 100 \
  --access Allow --direction Inbound --protocol '*' \
  --source-address-prefix VirtualNetwork --source-port-range '*' \
  --destination-address-prefix VirtualNetwork --destination-port-range '*'

az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "AllowVnetInBound" --priority 4090 \
  --access Allow --direction Inbound --protocol '*' \
  --source-address-prefix VirtualNetwork --source-port-range '*' \
  --destination-address-prefix VirtualNetwork --destination-port-range '*'

az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "AllowAzureLoadBalancerInBound" --priority 4091 \
  --access Allow --direction Inbound --protocol '*' \
  --source-address-prefix AzureLoadBalancer --source-port-range '*' \
  --destination-address-prefix '*' --destination-port-range '*'

az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "DenyAllInBound" --priority 4096 \
  --access Deny --direction Inbound --protocol '*' \
  --source-address-prefix '*' --source-port-range '*' \
  --destination-address-prefix '*' --destination-port-range '*'

###Outbound
az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "Allow-Databricks-Outbound" --priority 100 \
  --access Allow --direction Outbound --protocol '*' \
  --source-address-prefix VirtualNetwork --source-port-range '*' \
  --destination-address-prefix VirtualNetwork --destination-port-range '*'

az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "Allow-Databricks-Service" --priority 101 \
  --access Allow --direction Outbound --protocol Tcp \
  --source-address-prefix VirtualNetwork --source-port-range '*' \
  --destination-address-prefix AzureDatabricks --destination-port-ranges 443 3306 8443-8451

az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "Allow-SQL" --priority 102 \
  --access Allow --direction Outbound --protocol Tcp \
  --source-address-prefix VirtualNetwork --source-port-range '*' \
  --destination-address-prefix Sql --destination-port-range 3306

az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "Allow-Storage" --priority 103 \
  --access Allow --direction Outbound --protocol Tcp \
  --source-address-prefix VirtualNetwork --source-port-range '*' \
  --destination-address-prefix Storage --destination-port-range 443

az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "Allow-EventHub" --priority 104 \
  --access Allow --direction Outbound --protocol Tcp \
  --source-address-prefix VirtualNetwork --source-port-range '*' \
  --destination-address-prefix EventHub --destination-port-range 9093

az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "AllowVnetOutBound" --priority 4090 \
  --access Allow --direction Outbound --protocol '*' \
  --source-address-prefix VirtualNetwork --source-port-range '*' \
  --destination-address-prefix VirtualNetwork --destination-port-range '*'

az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "AllowInternetOutBound" --priority 4091 \
  --access Allow --direction Outbound --protocol '*' \
  --source-address-prefix '*' --source-port-range '*' \
  --destination-address-prefix Internet --destination-port-range '*'

az network nsg rule create --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
  --name "DenyAllOutBound" --priority 4096 \
  --access Deny --direction Outbound --protocol '*' \
  --source-address-prefix '*' --source-port-range '*' \
  --destination-address-prefix '*' --destination-port-range '*'


##Create Databricks Workspace
az databricks workspace create \
  --resource-group $RESOURCE_GROUP \
  --name $WORKSPACE_NAME \
  --location $LOCATION \
  --sku standard \
  --managed-resource-group $MANAGED_RG \
  --public-subnet $SUBNET_PUBLIC_NAME \
  --private-subnet $SUBNET_PRIVATE_NAME \
  --enable-no-public-ip true \
  --tags Environment=prd Project=Dataplatform Department="Digital & IT" \
  --vnet "/subscriptions/86093bd5-474b-461b-ac98-eab43df6459b/resourceGroups/rg-dataplatform_extra/providers/Microsoft.Network/virtualNetworks/vnet-dataplatform"
