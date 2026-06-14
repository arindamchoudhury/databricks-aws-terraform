# Account IAM unit — owns account-global users/groups. Applied ONCE for the whole
# Databricks account (shared by all envs). Only needs the account (mws) provider.

include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

include "mws" {
  path           = "${dirname(find_in_parent_folders("root.hcl"))}/_common/databricks-mws.hcl"
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/account-iam"
}

inputs = {
  iam = jsondecode(file("${get_terragrunt_dir()}/iam.json"))
}
