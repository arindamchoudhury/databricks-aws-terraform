output "metastore_id" {
  value = local.metastore_id
}

output "catalog_name" {
  value = databricks_catalog.this.id
}
