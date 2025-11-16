terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

data "azurerm_subscription" "primary" {}

data "azuread_group" "lab_admins" {
  display_name = "IT Lab Administrators"
}

resource "azurerm_management_group" "lab_mg" {
  display_name = "AZ104 Management Group"
  name         = "az104-mg1" # Унікальний ID для групи керування
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

resource "azurerm_resource_group" "lab_rg" {
  name     = "az104-02a-rg1"
  location = "West Europe"
}

resource "azurerm_role_assignment" "lab_role_assignment" {
  scope              = azurerm_resource_group.lab_rg.id
  role_definition_id = azurerm_role_definition.vm_operator_custom.role_definition_resource_id
  principal_id       = data.azuread_group.lab_admins.id
}

data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag and its value on resource groups"
}

resource "azurerm_management_group_policy_assignment" "require_tag_assignment" {
  name                 = "require-costcenter-tag"
  display_name         = "Require CostCenter tag on RGs"
  policy_definition_id = data.azurerm_policy_definition.require_tag.id
  management_group_id  = azurerm_management_group.lab_mg.id

  parameters = jsonencode({
    "tagName" : {
      "value" : "CostCenter"
    },
    "tagValue" : {
      "value" : "Contoso"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "iso27001_assignment" {
  name                 = "audit-iso27001-controls"
  display_name         = "Audit ISO 27001 Controls"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/5e4ff661-23bf-42fa-8e3a-309a55091cc7"
  management_group_id  = azurerm_management_group.lab_mg.id
}

resource "azurerm_resource_group" "lab_rg_compliant" {
  name     = "az104-02b-rg1"
  location = "West Europe"
  tags = {
    CostCenter = "Contoso"
  }
}

resource "azurerm_management_lock" "rg_lock" {
  name       = "rg-lock"
  scope      = azurerm_resource_group.lab_rg.id
  lock_level = "CanNotDelete"
  notes      = "This RG is locked to prevent accidental deletion."
}

