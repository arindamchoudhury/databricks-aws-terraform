# Databricks ACCOUNT (mws) provider — included by layers that talk to the
# accounts API (02-workspace, 03-unity-catalog). Generates the provider block
# and its credential variables, and supplies their values (non-secret from
# env.hcl, secrets from the gitignored secrets.hcl).

locals {
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  secrets = read_terragrunt_config(find_in_parent_folders("secrets.hcl")).locals
}

generate "provider_mws" {
  path      = "provider_mws_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "databricks" {
  alias         = "mws"
  host          = "https://accounts.cloud.databricks.com"
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}
EOF
}

# These cred vars are NOT declared by the modules — Terragrunt owns them so a
# module can be used as a root unit without re-declaring provider plumbing.
generate "vars_mws" {
  path      = "vars_mws_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "databricks_account_id" {
  type = string
}

variable "databricks_client_id" {
  type = string
}

variable "databricks_client_secret" {
  type      = string
  sensitive = true
}
EOF
}

inputs = {
  databricks_account_id    = local.env.databricks_account_id
  databricks_client_id     = local.secrets.databricks_client_id
  databricks_client_secret = local.secrets.databricks_client_secret
}
