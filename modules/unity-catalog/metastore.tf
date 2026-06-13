# Databricks auto-creates one metastore per region for all accounts created after Nov 2023.
# Look it up by name rather than creating a new one.
data "databricks_metastores" "all" {
  provider = databricks.mws
}

locals {
  # Default naming pattern: metastore_aws_<region_with_underscores>
  # e.g. eu-central-1 → metastore_aws_eu_central_1
  metastore_name = var.metastore_name != "" ? var.metastore_name : "metastore_aws_${replace(var.region, "-", "_")}"
  metastore_id   = data.databricks_metastores.all.ids[local.metastore_name]
}

resource "databricks_metastore_assignment" "this" {
  provider     = databricks.mws
  metastore_id = local.metastore_id
  workspace_id = var.workspace_id
}

resource "databricks_default_namespace_setting" "this" {
  provider = databricks.workspace
  namespace {
    value = var.catalog_name
  }
  depends_on = [databricks_metastore_assignment.this]
}
