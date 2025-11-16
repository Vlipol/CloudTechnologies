variable "admin_username" {
  description = "Ім'я адміністратора для VM."
  type        = string
  default     = "TestAdmin"
}

variable "admin_password" {
  description = "Пароль адміністратора для VM. Має бути складним."
  type        = string
  sensitive   = true
}

# Ресурси для VNet 1
variable "resource_group_name_1" {
  description = "Назва групи ресурсів для VNet 1."
  type        = string
  default     = "az104-05-rg1"
}

variable "location_1" {
  description = "Регіон для VNet 1."
  type        = string
  default     = "West Europe"
}

# Ресурси для VNet 2
variable "resource_group_name_2" {
  description = "Назва групи ресурсів для VNet 2."
  type        = string
  default     = "az104-05-rg2"
}

variable "location_2" {
  description = "Регіон для VNet 2."
  type        = string
  default     = "West US" # Інший регіон, як у лабі
}