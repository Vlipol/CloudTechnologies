output "storage_account_name" {
  description = "Назва нашого облікового запису зберігання."
  value       = azurerm_storage_account.sa.name
}

output "storage_account_primary_access_key" {
  description = "Первинний ключ доступу (Завдання 3)."
  value       = azurerm_storage_account.sa.primary_access_key
  sensitive   = true
}

output "storage_account_sas_token" {
  description = "SAS Токен (Завдання 3)."
  value       = data.azurerm_storage_account_sas.sas.sas
  sensitive   = true
}