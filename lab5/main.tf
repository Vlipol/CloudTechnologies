terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

#East US
resource "azurerm_resource_group" "rg1" {
  name     = var.resource_group_name_1
  location = var.location_1
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "az104-05-vnet1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = ["10.50.0.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet-0"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.50.0.0/24"]
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "az104-05-nsg1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

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

resource "azurerm_subnet_network_security_group_association" "assoc1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_public_ip" "pip1" {
  name                = "az104-05-pip1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic1" {
  name                = "az104-05-nic1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  enable_ip_forwarding = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip1.id
  }
}

resource "azurerm_virtual_machine" "vm1" {
  name                  = "az104-05-vm-1"
  location              = azurerm_resource_group.rg1.location
  resource_group_name   = azurerm_resource_group.rg1.name
  network_interface_ids = [azurerm_network_interface.nic1.id]
  vm_size               = "Standard_B2s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "az104-05-vm1-osdisk"
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


#West US
resource "azurerm_resource_group" "rg2" {
  name     = var.resource_group_name_2
  location = var.location_2
}

resource "azurerm_virtual_network" "vnet2" {
  name                = "az104-05-vnet2"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  address_space       = ["10.51.0.0/16"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet-0"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.51.0.0/24"]
}

resource "azurerm_network_security_group" "nsg2" {
  name                = "az104-05-nsg2"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name

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

resource "azurerm_subnet_network_security_group_association" "assoc2" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg2.id
}

resource "azurerm_public_ip" "pip2" {
  name                = "az104-05-pip2"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic2" {
  name                = "az104-05-nic2"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.51.0.4"
    public_ip_address_id          = azurerm_public_ip.pip2.id # <--- ДОДАЙТЕ ЦЕЙ РЯДОК
  }
}

resource "azurerm_virtual_machine" "vm2" {
  name                  = "az104-05-vm-2"
  location              = azurerm_resource_group.rg2.location
  resource_group_name   = azurerm_resource_group.rg2.name
  network_interface_ids = [azurerm_network_interface.nic2.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "az104-05-vm2-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm2"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  os_profile_windows_config {
    provision_vm_agent = true
  }
}

#PEERING
resource "azurerm_virtual_network_peering" "peering1_to_2" {
  name                      = "peering-vnet1-to-vnet2"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "peering2_to_1" {
  name                      = "peering-vnet2-to-vnet1"
  resource_group_name       = azurerm_resource_group.rg2.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

data "azurerm_network_interface" "nic1_data" {
  name                = azurerm_network_interface.nic1.name
  resource_group_name = azurerm_resource_group.rg1.name
  depends_on = [ azurerm_virtual_machine.vm1 ]
}

resource "azurerm_route_table" "route_table" {
  name                = "az104-05-rt"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  route {
    name           = "route-vnet1-to-vnet2"
    address_prefix = "10.51.0.0/16" # Адресний простір vnet2
    next_hop_type  = "VirtualAppliance"
    # IP-адреса нашого "роутера" (vm-1)
    next_hop_in_ip_address = data.azurerm_network_interface.nic1_data.private_ip_address
  }

  disable_bgp_route_propagation = false
}

resource "azurerm_subnet_route_table_association" "rt_assoc" {
  subnet_id      = azurerm_subnet.subnet1.id
  route_table_id = azurerm_route_table.route_table.id
}