output "vm0_public_ip" {
  description = "Публічна IP-адреса віртуальної машини vm-0."
  value       = azurerm_public_ip.pip0.ip_address
}