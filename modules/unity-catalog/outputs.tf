output "metastore_id" {
  value = databricks_metastore.this.id
}

output "catalog_name" {
  value = databricks_catalog.this.id
}

output "metastore_bucket" {
  value = aws_s3_bucket.metastore.id
}
