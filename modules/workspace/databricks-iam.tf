resource "databricks_user" "this" {
  for_each     = { for u in var.iam.users : u.user_name => u }
  provider     = databricks.mws
  user_name    = each.value.user_name
  display_name = each.value.display_name
}

resource "databricks_group" "this" {
  for_each     = { for g in var.iam.groups : g.name => g }
  provider     = databricks.mws
  display_name = each.key
}

resource "databricks_group_member" "this" {
  for_each = {
    for pair in flatten([
      for g in var.iam.groups : [
        for m in g.members : { group = g.name, user = m }
      ]
    ]) : "${pair.group}:${pair.user}" => pair
  }
  provider  = databricks.mws
  group_id  = databricks_group.this[each.value.group].id
  member_id = databricks_user.this[each.value.user].id
}
