variable "name_prefix" {
  type = string
}

variable "assets_bucket_id" {
  type = string
}

variable "assets_bucket_regional_domain_name" {
  type = string
}

variable "logs_bucket_domain_name" {
  type = string
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN del cert ACM en us-east-1. Vacío = usar cert default *.cloudfront.net."
  default     = ""
}

variable "aliases" {
  type    = list(string)
  default = []
}

variable "lambda_edge_arn" {
  type        = string
  description = "ARN calificado (con versión) de la Lambda@Edge para viewer-response."
}

variable "enable_waf" {
  type    = bool
  default = true
}
