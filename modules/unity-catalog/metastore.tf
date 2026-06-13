resource "databricks_metastore" "this" {
  provider      = databricks.mws
  name          = "${var.prefix}-metastore"
  storage_root  = "s3://${aws_s3_bucket.metastore.id}/metastore"
  owner         = var.admin_user
  region        = var.region
  force_destroy = true
}

resource "databricks_metastore_data_access" "this" {
  provider     = databricks.mws
  metastore_id = databricks_metastore.this.id
  name         = "${var.prefix}-uc-storage-credential"
  aws_iam_role {
    role_arn = aws_iam_role.uc_storage.arn
  }
  is_default = true
  depends_on = [aws_iam_role_policy.uc_storage]
}

resource "databricks_metastore_assignment" "this" {
  provider     = databricks.mws
  metastore_id = databricks_metastore.this.id
  workspace_id = var.workspace_id
}

resource "databricks_default_namespace_setting" "this" {
  provider = databricks.workspace
  namespace {
    value = var.catalog_name
  }
  depends_on = [databricks_metastore_assignment.this]
}
