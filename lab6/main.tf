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
      # Дозволяє 'destroy' видаляти групи з ресурсами
      prevent_deletion_if_contains_resources = false
    }
  }
}

# 1. Група ресурсів
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. VNet та підмережа
resource "azurerm_virtual_network" "vnet" {
  name                = "az104-06-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.60.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-0"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.0.0/24"]
}

# 3. Група безпеки (NSG) - ДУЖЕ ВАЖЛИВО!
resource "azurerm_network_security_group" "nsg" {
  name                = "az104-06-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Дозволяє RDP (порт 3389) для підключення
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

  # Дозволяє HTTP (порт 80) для Load Balancer
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*" # У лабі тут "Internet", що те саме
    destination_address_prefix = "*"
  }
}

# 4. Публічна IP-адреса для Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "az104-06-pip-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # Стандартний SKU, як у лабі
}

# 5. Load Balancer (Завдання 3)
resource "azurerm_lb" "lb" {
  name                = "az104-06-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "lb-frontend"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

# 6. Backend Pool (Завдання 4)
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "lb-backend-pool"
}

# 7. Health Probe (Завдання 4)
resource "azurerm_lb_probe" "probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "lb-probe"
  port            = 80
  protocol        = "Tcp"
}

# 8. Load Balancer Rule (Завдання 4)
resource "azurerm_lb_rule" "rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.probe.id
}

# 9. Створення ДВОХ VM, NIC та Public IP (Завдання 1)
# Ми використовуємо 'count' для створення 2 однакових наборів ресурсів
variable "vm_count" {
  default = 2
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "az104-06-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Прив'язка NIC до NSG
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Прив'язка NIC до Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "pool_assoc" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

resource "azurerm_virtual_machine" "vm" {
  count                 = var.vm_count
  name                  = "az104-06-vm-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "az104-06-vm-${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm${count.index}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  os_profile_windows_config {
    provision_vm_agent = true
  }
}

# 10. Встановлення IIS (Автоматизація Завдання 2)
resource "azurerm_virtual_machine_extension" "iis" {
  count                = var.vm_count
  name                 = "IIS-Install"
  virtual_machine_id   = azurerm_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

    settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools; New-NetFirewallRule -DisplayName 'Allow HTTP In' -Protocol TCP -LocalPort 80 -Action Allow\""
    }
SETTINGS
}

# --- ЗАВДАННЯ 6: IMPLEMENT AZURE APPLICATION GATEWAY ---

# 1. Створення окремої підмережі для App Gateway
resource "azurerm_subnet" "app_gateway_subnet" {
  name                 = "subnet-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.1.0/24"] # Новий діапазон, не перетинається
}

# 2. Публічна IP-адреса для App Gateway
resource "azurerm_public_ip" "appgw_pip" {
  name                = "az104-06-pip-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 3. Створення Application Gateway
resource "azurerm_application_gateway" "appgw" {
  name                = "az104-06-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  ssl_policy {
    policy_name = "AppGwSslPolicy20220101"
    policy_type = "Predefined"
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.app_gateway_subnet.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  # 4. Backend Pool (з IP-адресами)
  # (Ось виправлене/об'єднане визначення)
  backend_address_pool {
    name = "appgw-backend-pool"
    ip_addresses = [
      azurerm_network_interface.nic[0].private_ip_address,
      azurerm_network_interface.nic[1].private_ip_address
    ]
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  # 5. HTTP Listener та Rule (з'єднує все)
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "appgw-backend-pool"
    backend_http_settings_name = "http-settings"
  }
}