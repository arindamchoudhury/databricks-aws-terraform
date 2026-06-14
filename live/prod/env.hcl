# Per-environment values for prod. Same shape as dev/env.hcl — only values differ.
locals {
  region       = "us-east-1"
  prefix       = "dbx-prod"
  state_bucket = "REPLACE-with-state-bucket"

  databricks_account_id = "REPLACE-with-databricks-account-uuid"
  admin_user            = "arindam@live.com"

  # 01-networking
  vpc_cidr           = "10.1.0.0/16"
  private_subnets    = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets     = ["10.1.0.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
  enable_nat_gateway = false

  # 02-workspace
  workspace_name = "" # defaults to prefix
}
