variable "function_name" {
  type = string
}

variable "source_dir" {
  type        = string
  description = "Directorio que contiene index.js (y package.json) de la Lambda."
}

variable "runtime" {
  type    = string
  default = "nodejs20.x"
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "timeout" {
  type    = number
  default = 5
}
