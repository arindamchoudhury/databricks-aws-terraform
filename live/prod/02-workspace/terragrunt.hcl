# Workspace unit (prod). Identical to dev — only env.hcl / iam.json values differ.

include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

include "mws" {
  path           = "${dirname(find_in_parent_folders("root.hcl"))}/_common/databricks-mws.hcl"
  merge_strategy = "deep"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules/workspace"
}

dependency "account" {
  config_path = "../../account/00-account"
  mock_outputs = {
    group_ids = { "${local.env.prefix}-admins" = "000000000000000" }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "networking" {
  config_path = "../01-networking"
  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock-a", "subnet-mock-b"]
    security_group_ids = ["sg-mock"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  workspace_name     = local.env.workspace_name
  admin_group_id     = dependency.account.outputs.group_ids["${local.env.prefix}-admins"]
  vpc_id             = dependency.networking.outputs.vpc_id
  private_subnet_ids = dependency.networking.outputs.private_subnet_ids
  security_group_ids = dependency.networking.outputs.security_group_ids
}
