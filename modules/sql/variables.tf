variable "organization" {
  type        = string
  default     = "tradersclub"
  description = "(required)"
}
variable "environment" {
  type        = string
  description = "(required)"
}

variable "region" {
  type        = string
  description = "(required)"
}

variable "project_id" {
  type        = string
  description = "(required)"
}

variable "mysqls" {
  type    = set(any)
  default = []
}

