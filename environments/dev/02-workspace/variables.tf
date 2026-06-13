variable "region" {
  type    = string
  default = "us-east-1"
}

variable "prefix" {
  type    = string
  default = "dbx-dev"
}

variable "state_bucket" {
  type        = string
  description = "S3 bucket containing Terraform state files (from bootstrap outputs)"
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

variable "workspace_name" {
  type    = string
  default = ""
}

variable "workspace_admin_group" {
  type        = string
  default     = "admins"
  description = "Group name to assign ADMIN on the workspace"
}
