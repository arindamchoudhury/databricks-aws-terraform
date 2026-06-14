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

# NOTE: the variable is intentionally NOT marked `sensitive` as a whole — scope
# names and keys are identifiers used as for_each keys (which cannot be sensitive).
# Only each secret's `value` is sensitive; that is wrapped with sensitive() in
# secrets.tf at the point it is written to databricks_secret.string_value.
variable "secrets" {
  description = "Secret scopes and secrets to create in the workspace (from secrets.json)"
  type = object({
    scopes = list(object({
      name    = string
      secrets = list(object({ key = string, value = string }))
    }))
  })
  default = { scopes = [] }
}
