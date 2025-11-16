output "vm1_public_ip" {
  description = "Публічна IP-адреса vm-1 (East US)."
  value       = azurerm_public_ip.pip1.ip_address
}

output "vm1_private_ip" {
  description = "Приватна IP-адреса vm-1."
  value       = data.azurerm_network_interface.nic1_data.private_ip_address
}

output "vm2_public_ip" {
  description = "Публічна IP-адреса vm-2 (West US)."
  value       = azurerm_public_ip.pip2.ip_address
}

output "vm2_private_ip" {
  description = "Приватна IP-адреса vm-2."
  value       = azurerm_network_interface.nic2.private_ip_address
}