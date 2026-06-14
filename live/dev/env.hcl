# Per-environment values for dev. The ONLY place dev differs from prod.
# Adding "staging" = copy this file + the unit folders, change these values.
locals {
  region       = "eu-central-1"
  prefix       = "dbx-dev"
  state_bucket = "arindam-databricks-tf-state-dd660bdc" # output of bootstrap

  databricks_account_id = "6d1f36bc-6560-40ce-a6ca-84a9ba7ecce5"
  admin_user            = "arindam@live.com"

  # 01-networking
  vpc_cidr           = "10.0.0.0/16"
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.0.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  enable_nat_gateway = false # serverless-only; flip true for classic compute egress

  # 02-workspace
  workspace_name = ""               # defaults to prefix
  admin_group    = "dbx-dev-admins" # dev has its own admin group (members can differ from staging/prod)

  # workspace_id / workspace_url are NOT set here — they flow from the
  # 02-workspace layer into 03-unity-catalog via a Terragrunt dependency block.
}
