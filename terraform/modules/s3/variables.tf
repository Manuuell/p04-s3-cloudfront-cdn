variable "name_prefix" {
  type = string
}

variable "logs_retention_days" {
  type    = number
  default = 90
}

variable "uploads_ia_transition" {
  type    = number
  default = 30
}

variable "uploads_glacier_transition" {
  type    = number
  default = 90
}

variable "uploads_expiration_days" {
  type    = number
  default = 365
}
