# Account-level Databricks IAM, owned ONCE at account scope (not per workspace).
# Account users/groups are global to the Databricks account, so managing them in
# each workspace env caused name collisions and made workspace destroys able to
# delete account identities. This layer is the single owner.

# Users are REFERENCED, not created — they come from the account console / SCIM /
# IdP. The data source errors if a listed user is missing, which is the correct
# signal (this layer wires access; it does not provision people). To provision
# users from Terraform instead, switch this to a databricks_user resource.
data "databricks_user" "this" {
  for_each  = { for u in var.iam.users : u.user_name => u }
  provider  = databricks.mws
  user_name = each.value.user_name
}

# Groups ARE owned here. Names must not be the reserved built-ins ("admins" /
# "users"); use a custom name such as "<prefix>-admins". force adopts an
# existing group of the same name instead of erroring.
resource "databricks_group" "this" {
  for_each     = { for g in var.iam.groups : g.name => g }
  provider     = databricks.mws
  display_name = each.key
  force        = true
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
  member_id = data.databricks_user.this[each.value.user].id
}
