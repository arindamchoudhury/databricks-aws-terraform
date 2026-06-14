# Per-environment values for prod. Same shape as dev/env.hcl — only values differ.
locals {
  region       = "eu-central-1"
  prefix       = "dbx-prod"
  state_bucket = "prod-databricks-tf-state-dd660bdc"

  databricks_account_id = "6d1f36bc-6560-40ce-a6ca-84a9ba7ecce5"
  admin_user            = "arindam@live.com"

  # 01-networking
  vpc_cidr           = "10.1.0.0/16"
  private_subnets    = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets     = ["10.1.0.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  enable_nat_gateway = false

  # 02-workspace
  workspace_name = "" # defaults to prefix
}
