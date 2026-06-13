data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket       = var.state_bucket
    key          = "dev/networking/terraform.tfstate"
    region       = var.region
    use_lockfile = true
  }
}

module "workspace" {
  source = "../../../modules/workspace"

  providers = {
    databricks.mws = databricks.mws
  }

  prefix                = var.prefix
  region                = var.region
  databricks_account_id = var.databricks_account_id
  vpc_id                = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnet_ids    = data.terraform_remote_state.networking.outputs.private_subnet_ids
  security_group_ids    = data.terraform_remote_state.networking.outputs.security_group_ids
  workspace_name        = var.workspace_name
}
