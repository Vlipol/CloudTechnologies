terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "lab_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  address_space       = ["10.40.0.0/20"] # Як у лабі
}

resource "azurerm_subnet" "subnet0" {
  name                 = "subnet-0"
  resource_group_name  = azurerm_resource_group.lab_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.40.0.0/24"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet-1"
  resource_group_name  = azurerm_resource_group.lab_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.40.1.0/24"]
}

resource "azurerm_network_security_group" "nsg0" {
  name                = "az104-04-nsg-subnet-0"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc0" {
  subnet_id                 = azurerm_subnet.subnet0.id
  network_security_group_id = azurerm_network_security_group.nsg0.id
}

resource "azurerm_public_ip" "pip0" {
  name                = "az104-04-pip-0"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic0" {
  name                = "az104-04-nic-0"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet0.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip0.id
  }
}

resource "azurerm_virtual_machine" "vm0" {
  name                  = "az104-04-vm-0"
  location              = azurerm_resource_group.lab_rg.location
  resource_group_name   = azurerm_resource_group.lab_rg.name
  network_interface_ids = [azurerm_network_interface.nic0.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "az104-04-vm-0-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm0"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

resource "azurerm_network_interface" "nic1" {
  name                = "az104-04-nic-1"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static" # Як у лабі
    private_ip_address            = "10.40.1.4" # Статична IP
  }
}

resource "azurerm_virtual_machine" "vm1" {
  name                  = "az104-04-vm-1"
  location              = azurerm_resource_group.lab_rg.location
  resource_group_name   = azurerm_resource_group.lab_rg.name
  network_interface_ids = [azurerm_network_interface.nic1.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "az104-04-vm-1-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm1"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

#DNS
resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "contoso.com" # Як у лабі
  resource_group_name = azurerm_resource_group.lab_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "vnet-dns-link"
  resource_group_name   = azurerm_resource_group.lab_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  
  registration_enabled  = true 
}