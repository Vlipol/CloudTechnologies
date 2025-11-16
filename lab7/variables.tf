variable "resource_group_name" {
  description = "Назва групи ресурсів."
  type        = string
  default     = "az104-07-rg"
}

variable "location" {
  description = "Регіон Azure."
  type        = string
  default     = "West Europe"
}

variable "storage_account_suffix" {
  description = "Унікальний суфікс для облікового запису зберігання."
  type        = string
}