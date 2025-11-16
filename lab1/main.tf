terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

provider "azuread" {}

# === 1. Створення користувачів ===
resource "azuread_user" "user1" {
  user_principal_name = "user1@${data.azuread_client_config.current.tenant_id}.onmicrosoft.com"
  display_name        = "User One"
  password            = "P@ssword1234!"
  force_password_change = false
}

resource "azuread_user" "user2" {
  user_principal_name = "user2@${data.azuread_client_config.current.tenant_id}.onmicrosoft.com"
  display_name        = "User Two"
  password            = "P@ssword1234!"
  force_password_change = false
}

# === 2. Створення групи ===
resource "azuread_group" "dev_group" {
  display_name     = "Developers"
  security_enabled = true
  mail_enabled     = false
}

# === 3. Додавання користувачів до групи ===
resource "azuread_group_member" "user1_in_group" {
  group_object_id  = azuread_group.dev_group.id
  member_object_id = azuread_user.user1.id
}

resource "azuread_group_member" "user2_in_group" {
  group_object_id  = azuread_group.dev_group.id
  member_object_id = azuread_user.user2.id
}

# === 4. Отримання інформації про підключеного клієнта ===
data "azuread_client_config" "current" {}
