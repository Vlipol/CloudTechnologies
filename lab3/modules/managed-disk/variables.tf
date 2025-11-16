variable "disk_name" {
  description = "Назва керованого диска."
  type        = string
}

variable "resource_group_name" {
  description = "Назва групи ресурсів, до якої належить диск."
  type        = string
}

variable "location" {
  description = "Регіон диска."
  type        = string
}

variable "disk_size_gb" {
  description = "Розмір диска в ГБ."
  type        = number
  default     = 32
}