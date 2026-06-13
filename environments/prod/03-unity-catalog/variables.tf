variable "region" {
  type    = string
  default = "us-east-1"
}

variable "prefix" {
  type    = string
  default = "dbx-prod"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account UUID"
}

variable "databricks_client_id" {
  type        = string
  description = "Databricks service principal client ID"
}

variable "databricks_client_secret" {
  type        = string
  sensitive   = true
  description = "Databricks service principal client secret"
}

variable "workspace_id" {
  type        = string
  description = "Databricks workspace numeric ID (from 02-workspace output)"
}

variable "workspace_url" {
  type        = string
  description = "Databricks workspace URL (from 02-workspace output)"
}

variable "admin_user" {
  type        = string
  description = "Email of the admin user to receive catalog grants"
}

variable "catalog_name" {
  type    = string
  default = "main"
}
