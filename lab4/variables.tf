variable "resource_group_name" {
  description = "Назва групи ресурсів."
  type        = string
  default     = "az104-04-rg"
}

variable "location" {
  description = "Регіон Azure."
  type        = string
  default     = "West US"
}

variable "vnet_name" {
  description = "Назва віртуальної мережі."
  type        = string
  default     = "az104-04-vnet1"
}

variable "admin_username" {
  description = "Ім'я адміністратора для VM."
  type        = string
  default     = "TestAdmin"
}

variable "admin_password" {
  description = "Пароль адміністратора для VM. Має бути складним."
  type        = string
  sensitive   = true # Приховує пароль у виводі
}