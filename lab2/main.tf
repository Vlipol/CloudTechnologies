terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "primary" {}

data "azuread_group" "lab_admins" {
  display_name = "IT Lab Administrators"
}

resource "azurerm_management_group" "lab_mg" {
  display_name = "AZ104 Management Group"
  name         = "az104-mg1" # Це унікальний ID групи керування
}

resource "azurerm_role_definition" "vm_operator_custom" {
  name        = "Virtual Machine Operator"
  scope       = data.azurerm_subscription.primary.id
  description = "Allows to create and manage virtual machines."

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/listKeys/action",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/write",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Resources/subscriptions/resourceGroups/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id,
  ]
}

# --- Завдання 3: Створення ресурсної групи та призначення ролі ---
# 1. Створюємо ресурсну групу, до якої будемо надавати доступ
resource "azurerm_resource_group" "lab_rg" {
  name     = "az104-02a-rg1"
  location = "West Europe" # Можете змінити на ваш регіон
}

# 2. Призначаємо створену кастомну роль групі "IT Lab Administrators"
#    в межах (scope) нової ресурсної групи
resource "azurerm_role_assignment" "lab_role_assignment" {
  scope              = azurerm_resource_group.lab_rg.id
  role_definition_id = azurerm_role_definition.vm_operator_custom.role_definition_resource_id
  principal_id       = data.azuread_group.lab_admins.object_id
}
