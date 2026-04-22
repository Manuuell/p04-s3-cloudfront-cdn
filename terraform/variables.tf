variable "project_name" {
  type        = string
  description = "Nombre base del proyecto, usado como prefijo de recursos."
  default     = "p04-cdn"
}

variable "environment" {
  type        = string
  description = "Entorno (dev, prod)."
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment debe ser 'dev' o 'prod'."
  }
}

variable "owner" {
  type        = string
  description = "Owner/equipo responsable para tagging."
  default     = "equipo-p04"
}

variable "aws_region" {
  type        = string
  description = "Región AWS principal."
  default     = "us-east-1"
}

variable "use_custom_domain" {
  type        = bool
  description = "Si es false, usa la URL por defecto *.cloudfront.net y omite Route53/ACM."
  default     = false
}

variable "domain_name" {
  type        = string
  description = "Dominio principal (ej. cdn.ejemplo.com). Ignorado si use_custom_domain=false."
  default     = ""
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "SANs adicionales para el certificado ACM."
  default     = []
}

variable "logs_retention_days" {
  type        = number
  description = "Retención de logs de CloudFront en días."
  default     = 90
}

variable "uploads_ia_transition_days" {
  type    = number
  default = 30
}

variable "uploads_glacier_transition_days" {
  type    = number
  default = 90
}

variable "uploads_expiration_days" {
  type    = number
  default = 365
}

variable "enable_waf" {
  type        = bool
  description = "Habilitar WAF Web ACL con reglas managed de AWS."
  default     = true
}
