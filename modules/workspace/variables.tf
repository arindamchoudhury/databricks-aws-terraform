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
  description = "Databricks account UUID (from accounts.cloud.databricks.com)"
}

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
