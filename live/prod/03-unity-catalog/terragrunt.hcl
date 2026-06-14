# Unity Catalog unit (prod). Identical to dev — only env.hcl / secrets differ.

include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

include "mws" {
  path           = "${dirname(find_in_parent_folders("root.hcl"))}/_common/databricks-mws.hcl"
  merge_strategy = "deep"
}

include "workspace" {
  path           = "${dirname(find_in_parent_folders("root.hcl"))}/_common/databricks-workspace.hcl"
  merge_strategy = "deep"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules/unity-catalog"
}

dependency "workspace" {
  config_path = "../02-workspace"
  mock_outputs = {
    workspace_id  = "0000000000000000"
    workspace_url = "https://mock.cloud.databricks.com"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  admin_user    = local.env.admin_user
  catalog_name  = "main"
  workspace_id  = dependency.workspace.outputs.workspace_id
  workspace_url = dependency.workspace.outputs.workspace_url
  secrets       = fileexists("${get_terragrunt_dir()}/secrets.json") ? jsondecode(file("${get_terragrunt_dir()}/secrets.json")) : { scopes = [] }
}
