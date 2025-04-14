#Network Security Group (NSG)
resource "azurerm_network_security_group" "shir_nsg" {
  name                = "nsg-shir"
  location            = azurerm_resource_group.rg-dataplatform_extra.location
  resource_group_name = azurerm_resource_group.rg-dataplatform_extra.name
}

#Inbound Rules
resource "azurerm_network_security_rule" "shir_allow_rdp" {
  name                        = "allow-rdp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"     # Only allowed IP for rdp
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-dataplatform_extra.name
  network_security_group_name = azurerm_network_security_group.shir_nsg.name
}

resource "azurerm_network_security_rule" "allow_shir_inbound" {
  name                        = "allow-shir-inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"  #ADF communication port
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-dataplatform_extra.name
  network_security_group_name = azurerm_network_security_group.shir_nsg.name
}

resource "azurerm_network_security_rule" "allow_postgresql" {
  name                        = "allow-postgresql"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "10.100.22.182"     # On-premises PostgreSQL IP
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-dataplatform_extra.name
  network_security_group_name = azurerm_network_security_group.shir_nsg.name
}

resource "azurerm_network_security_rule" "allow_http_https" {
  name                        = "allow-http-https"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-dataplatform_extra.name
  network_security_group_name = azurerm_network_security_group.shir_nsg.name
}

#Outbound Rules
resource "azurerm_network_security_rule" "allow_outbound_https" {
  name                        = "allow-outbound-https"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"   #Communication with ADF
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-dataplatform_extra.name
  network_security_group_name = azurerm_network_security_group.shir_nsg.name
}

#NIC
resource "azurerm_network_interface" "shir_nic" {
  name                = "nic-dev-shir"
  location            = azurerm_resource_group.rg-dataplatform_extra.location
  resource_group_name = azurerm_resource_group.rg-dataplatform_extra.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets["sn-dev-adf-purview"].id
    private_ip_address_allocation = "Dynamic"
  }
}

data "azurerm_key_vault_secret" "shir_dev_password" {
  name         = "shir-dev-password"
  key_vault_id = azurerm_key_vault.kv_dev.id
}

#SHIR Vm
resource "azurerm_virtual_machine" "shir_vm" {
  name                  = "vm-dev-shir"
  location              = azurerm_resource_group.rg-dataplatform_extra.location
  resource_group_name   = azurerm_resource_group.rg-dataplatform_extra.name
  network_interface_ids = [azurerm_network_interface.shir_nic.id]
  vm_size               = "Standard_B2ms"
  tags                  = merge(var.common_tags, {"Environment" = "all"})

  storage_os_disk {
    name              = "osdisk-shir"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    #managed           = true
    os_type           = "Windows"
    disk_size_gb      = 128
  }

  os_profile {
    computer_name  = "shirvm"
    admin_username = "azureuser"
    admin_password = data.azurerm_key_vault_secret.shir_dev_password.value
  }
  #????
  os_profile_windows_config {
    provision_vm_agent = true
    enable_automatic_upgrades = true
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"  #Windows Server 2019 Datacenter
    version   = "latest"
  }

  identity {type = "SystemAssigned"}
}

#Do the installation in the machine
#Create the SHIR on ADF
#Install JVM
##https://www.java.com/en/download/manual.jsp
/*
IR@06ceef6d-03ba-4ce5-a570-81fb05816ce1@df-dataplatform-nadara-dev@ServiceEndpoint=df-dataplatform-nadara-dev.francecentral.datafactory.azure.net@/E4o6YppegGSH2wHiz2j9CGBosHuZfviIz+8J/VsiqA=
IR@06ceef6d-03ba-4ce5-a570-81fb05816ce1@df-dataplatform-nadara-dev@ServiceEndpoint=df-dataplatform-nadara-dev.francecentral.datafactory.azure.net@nwazpmJzSQFqU/D34ap5FcJdQzWVdPL+gvNZQSYU3B8=

Psql onprem
Host: 10.100.22.182
Port: 5432
Database: hub
User: timestamp_reader
Password: a,~"9mkOKqv2u}+)
*/