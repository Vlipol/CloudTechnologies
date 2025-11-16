variable "resource_group_name" {
  description = "Назва групи ресурсів."
  type        = string
  default     = "az104-rg3-tf"
}

variable "location" {
  description = "Регіон Azure для розгортання ресурсів."
  type        = string
  default     = "East US"
}