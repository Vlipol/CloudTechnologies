variable "resource_group_name" {
  description = "Назва групи ресурсів."
  type        = string
  default     = "az104-06-rg"
}

variable "location" {
  description = "Регіон Azure. (Використовуємо West Europe, щоб уникнути помилок SkuNotAvailable)"
  type        = string
  default     = "West Europe"
}

variable "admin_username" {
  description = "Ім'я адміністратора для VM."
  type        = string
  default     = "TestAdmin"
}

variable "admin_password" {
  description = "Пароль адміністратора для VM."
  type        = string
  sensitive   = true
}