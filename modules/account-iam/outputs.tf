output "group_ids" {
  description = "Map of group display_name => group id (for permission assignments)"
  value       = { for k, g in databricks_group.this : k => g.id }
}

output "user_ids" {
  description = "Map of user_name => user id"
  value       = { for k, u in data.databricks_user.this : k => u.id }
}
