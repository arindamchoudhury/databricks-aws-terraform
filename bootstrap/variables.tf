variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "prefix" {
  type        = string
  description = "Short prefix used in resource names, e.g. myorg"
  default     = "dbx"
}
