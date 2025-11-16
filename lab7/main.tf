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

# 1. Група ресурсів
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Обліковий запис зберігання (Завдання 1)
resource "azurerm_storage_account" "sa" {
  name                     = "staz10407${var.storage_account_suffix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  # 3. Налаштування брандмауера сховища (Завдання 5)
  network_rules {
    default_action             = "Deny"  # Блокуємо ВСІХ за замовчуванням
    bypass                     = ["AzureServices"] # Дозволяє іншим службам Azure
    virtual_network_subnet_ids = [azurerm_subnet.subnet.id] # Дозволяємо ТІЛЬКИ нашу VNet
  }
}

# 3. Контейнер Blob (Завдання 2)
resource "azurerm_storage_container" "container" {
  name                  = "az104-07-container"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# 4. Завантаження файлу Blob (Завдання 2)
resource "azurerm_storage_blob" "blob" {
  name                   = "lab.txt"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "lab.txt" # Посилається на наш локальний файл
  access_tier            = "Cool"    # Як у лабі
}

# 5. Файловий ресурс (File Share) (Завдання 4)
resource "azurerm_storage_share" "share" {
  name                 = "az104-07-share"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 1024 # 1 ГБ
}

# 6. Генерація SAS-токену (Завдання 3)
data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  https_only        = true

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = true
    table = true
    file  = true
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "1h") # Діє протягом 1 години

  permissions {
    # Дозволи, які ми хочемо (як у лабі)
    read = true
    add  = true
    list = true

    # Дозволи, які ми ПОВИННІ вказати як 'false'
    write   = false
    delete  = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

# --- ЗАВДАННЯ 5: NETWORK SECURITY ---

# 1. Створення VNet та підмережі
resource "azurerm_virtual_network" "vnet" {
  name                = "az104-07-vnet"
  address_space       = ["10.70.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "storage-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.70.0.0/24"]

  # 2. Увімкнення "Service Endpoint" для сховища
  # Це дозволяє підмережі "бачити" сховище приватно
  service_endpoints    = ["Microsoft.Storage"]
}