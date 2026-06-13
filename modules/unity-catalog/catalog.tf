resource "databricks_catalog" "this" {
  provider   = databricks.workspace
  name       = var.catalog_name
  comment    = "Main catalog for ${var.prefix}"
  depends_on = [databricks_metastore_assignment.this]
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

resource "databricks_grants" "catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.this.id
  grant {
    principal  = var.admin_user
    privileges = ["USE_CATALOG", "CREATE_SCHEMA", "CREATE_TABLE"]
  }
}

resource "databricks_grants" "bronze" {
  provider = databricks.workspace
  schema   = "${databricks_catalog.this.id}.${databricks_schema.bronze.id}"
  grant {
    principal  = var.admin_user
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "MODIFY"]
  }
}

resource "databricks_grants" "silver" {
  provider = databricks.workspace
  schema   = "${databricks_catalog.this.id}.${databricks_schema.silver.id}"
  grant {
    principal  = var.admin_user
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "MODIFY"]
  }
}

resource "databricks_grants" "gold" {
  provider = databricks.workspace
  schema   = "${databricks_catalog.this.id}.${databricks_schema.gold.id}"
  grant {
    principal  = var.admin_user
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "SELECT"]
  }
}
