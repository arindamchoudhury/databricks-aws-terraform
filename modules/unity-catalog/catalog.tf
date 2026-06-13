# Storage credential created first — uses hardcoded ARN string to avoid circular dependency
# (aws_iam_role.catalog_storage trust policy depends on the external_id this resource generates)
resource "databricks_storage_credential" "this" {
  provider = databricks.workspace
  name     = "${var.prefix}-catalog-storage"
  aws_iam_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-catalog-storage"
  }
}

resource "databricks_external_location" "catalog" {
  provider        = databricks.workspace
  name            = "${var.prefix}-catalog-location"
  url             = "s3://${aws_s3_bucket.catalog.id}"
  credential_name = databricks_storage_credential.this.name
  depends_on      = [time_sleep.wait_for_iam_propagation]
}

resource "databricks_catalog" "this" {
  provider     = databricks.workspace
  name         = var.catalog_name
  comment      = "Main catalog for ${var.prefix}"
  storage_root = "${databricks_external_location.catalog.url}/"
  depends_on   = [databricks_metastore_assignment.this]
}

resource "databricks_schema" "bronze" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.this.id
  name         = "bronze"
  comment      = "Raw ingestion layer"
}

resource "databricks_schema" "silver" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.this.id
  name         = "silver"
  comment      = "Cleaned and validated layer"
}

resource "databricks_schema" "gold" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.this.id
  name         = "gold"
  comment      = "Business-ready aggregations"
}

resource "time_sleep" "wait_for_schemas" {
  depends_on      = [databricks_schema.bronze, databricks_schema.silver, databricks_schema.gold]
  create_duration = "15s"
}

resource "databricks_grants" "catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.this.id
  grant {
    principal  = var.admin_user
    privileges = ["USE_CATALOG", "CREATE_SCHEMA", "CREATE_TABLE"]
  }
}

resource "databricks_grants" "bronze" {
  provider   = databricks.workspace
  schema     = databricks_schema.bronze.id
  depends_on = [time_sleep.wait_for_schemas]
  grant {
    principal  = var.admin_user
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "MODIFY"]
  }
}

resource "databricks_grants" "silver" {
  provider   = databricks.workspace
  schema     = databricks_schema.silver.id
  depends_on = [time_sleep.wait_for_schemas]
  grant {
    principal  = var.admin_user
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "MODIFY"]
  }
}

resource "databricks_grants" "gold" {
  provider   = databricks.workspace
  schema     = databricks_schema.gold.id
  depends_on = [time_sleep.wait_for_schemas]
  grant {
    principal  = var.admin_user
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "SELECT"]
  }
}
