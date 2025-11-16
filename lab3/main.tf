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

# 1. Створення групи ресурсів
resource "azurerm_resource_group" "lab_rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Виклик нашого модуля 5 разів
module "disk1" {
  source              = "./modules/managed-disk"
  disk_name           = "az104-disk1"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
}

module "disk2" {
  source              = "./modules/managed-disk"
  disk_name           = "az104-disk2"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
}

module "disk3" {
  source              = "./modules/managed-disk"
  disk_name           = "az104-disk3"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
}

module "disk4" {
  source              = "./modules/managed-disk"
  disk_name           = "az104-disk4"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
}

module "disk5" {
  source              = "./modules/managed-disk"
  disk_name           = "az104-disk5"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
}