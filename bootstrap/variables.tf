variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform state (choose your own, e.g. myorg-databricks-tf-state)"
}

variable "prefix" {
  type        = string
  description = "Short prefix used in resource names, e.g. myorg"
  default     = "dbx"
}
