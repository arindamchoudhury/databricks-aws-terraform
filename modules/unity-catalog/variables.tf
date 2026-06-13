variable "prefix" {
  type        = string
  description = "Short resource name prefix"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account UUID"
}

variable "workspace_id" {
  type        = string
  description = "Databricks workspace numeric ID (from workspace layer outputs)"
}

variable "admin_user" {
  type        = string
  description = "Email of the Databricks admin user to receive catalog grants"
}

variable "catalog_name" {
  type        = string
  description = "Name of the Unity Catalog catalog to create"
  default     = "main"
}
