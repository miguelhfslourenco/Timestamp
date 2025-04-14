#Activate sftp on SA
az storage account update --name sadataplatfnadara --resource-group rg-dataplatform_extra --enable-sftp true --tags Department="Digital & IT" Project=Dataplatform Environment=dev Owner="IT Department"
#Create sftp local user for vegetation
az storage account local-user create --account-name sadataplatfnadara -g rg-dataplatform_extra -n vegetation --home-directory dls-landing/satellite --permission-scope permissions=rw service=blob resource-name=dls-landing --ssh-authorized-key key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDxMBqlopsII40f9xiHvI73ZKq4nhVTQTPz7LLxD0Mu9wBMEVSzjL3bwHo883i4WP3F4rsS9+q4fzKzCDe+ALBocRHIBkB2vqoTvHjAsNfMC1k6xe79j53OC9nN6SEUFOppfsyf2MO0v4YecRDYb3Ux4QbbwFzvkHb8SUpc3Dj2hXyJwy8JXlnPoTrvsM2YZ+xUtQuTFgF9mMYNPjo/5YzO40PfpmYDATfnu2kth9JrYwCyjVnmekbX5h4esDQLoxL0+SLJVJQlylZFYa8E88WFCQ9O4ongioYyblXxmhT0TBOV2x05KEe0naRKLXe4mswqhIKncMppcePgLF5XummzkPJ3FEmfHKNpoo9w2whvwprK94TUEjpXnbCIfDctd2LOV9CO8FjJejrI7Fm7+f+41EQByRtT0YUvz5GW7RW/leJv7uLegdhKIqQGRozeUklG/Mfiz7NyLxkFD7VBEjtDjF1wS/tIu72Olkyf2KwXrxr0nMWZtkpx0I24l2mRGOO09IaKr17B8yjSe1BCBB1Ho1jTFmAfQxuK0tzWQww3lVnETD11KsaUVR9wBXJjoT4GtofoIp7qcsqnksCQg6mpDQ1o8J9K4LCdQ8vI8ECwj6Lkvrf7hPy4vOyXvYJDeYC+R3QZT7Vx7BTGD26qNxhwnNC4xOr3EenpwoGf+LNKUw=="
	Username: vegetation
	Connection String: sadataplatfnadara.vegetation@sadataplatfnadara.blob.core.windows.net
	Home directory: dls-landing/satellite
#ADF Git configuration
az datafactory configure-factory-repo --factory-resource-id "/subscriptions/86093bd5-474b-461b-ac98-eab43df6459b/resourceGroups/rg-dataplatform-dev/providers/Microsoft.DataFactory/factories/df-dataplatform-nadara-dev" --location "France Central" --subscription "86093bd5-474b-461b-ac98-eab43df6459b" 
--factory-vsts-configuration account-name="renantis" collaboration-branch="master" project-name="data-platform" repository-name="pipelines" root-folder="/" tenant-id=""
#--ids ??
###NOT WORKING By cli due to missing possibility to add the cidr, the only approach found was to create the subnets first but this way they can't be created on other RG than the one where vnet is###
#Add databricks extension for az cli
az extension add --name databricks
# Create private subnet
az network vnet subnet create --resource-group rg-dataplatform_extra --vnet-name vnet-dataplatform --name databricks-priv-dev --address-prefixes 10.100.68.128/25
# Create public subnet
az network vnet subnet create --resource-group rg-dataplatform_extra --vnet-name vnet-dataplatform --name databricks-pub-dev --address-prefixes 10.100.68.64/26
#Databricks Workspace
az databricks workspace create -g rg-dataplatform-dev -n databricks-workspace -l "France Central" --sku standard --enable-no-public-ip true --managed-resource-group rg-dataplatform_databricks-dev --private-subnet databricks-priv-dev --public-subnet databricks-pub-dev 
#################
