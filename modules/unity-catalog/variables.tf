variable "prefix" {
  type        = string
  description = "Short resource name prefix"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "metastore_name" {
  type        = string
  description = "Name of the existing metastore. Defaults to the Databricks auto-created pattern: metastore_aws_<region_underscored>"
  default     = ""
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

variable "secrets" {
  description = "Secret scopes and secrets to create in the workspace (from secrets.json)"
  sensitive   = true
  type = object({
    scopes = list(object({
      name    = string
      secrets = list(object({ key = string, value = string }))
    }))
  })
  default = { scopes = [] }
}
