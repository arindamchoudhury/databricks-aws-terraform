variable "prefix" {
  type        = string
  description = "Short resource name prefix"
}

variable "region" {
  type        = string
  description = "AWS region"
}

# NOTE: databricks_account_id is declared by Terragrunt (live/_common/databricks-mws.hcl)
# so the mws provider and this module's resources share one declaration. Do not
# re-declare it here or Terraform will error on a duplicate variable.

variable "vpc_id" {
  type        = string
  description = "VPC ID (from networking layer)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs (from networking layer)"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs (from networking layer)"
}

variable "workspace_name" {
  type        = string
  description = "Display name for the workspace (defaults to prefix)"
  default     = ""
}

variable "admin_group_id" {
  type        = string
  description = "ID of the account group to assign ADMIN on this workspace (from the 00-account layer)"
}
