module "unity_catalog" {
  source = "../../../modules/unity-catalog"

  providers = {
    databricks.mws       = databricks.mws
    databricks.workspace = databricks.workspace
  }

  prefix       = var.prefix
  region       = var.region
  workspace_id = var.workspace_id
  admin_user   = var.admin_user
  catalog_name = var.catalog_name
  secrets      = fileexists("${path.module}/secrets.json") ? jsondecode(file("${path.module}/secrets.json")) : { scopes = [] }
}
