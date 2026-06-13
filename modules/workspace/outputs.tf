output "workspace_url" {
  value = databricks_mws_workspaces.this.workspace_url
}

output "workspace_id" {
  value = databricks_mws_workspaces.this.workspace_id
}

output "cross_account_role_arn" {
  value = aws_iam_role.cross_account.arn
}

output "root_bucket" {
  value = aws_s3_bucket.root_storage.id
}
