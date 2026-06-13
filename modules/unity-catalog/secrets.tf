resource "databricks_secret_scope" "this" {
  for_each = { for s in var.secrets.scopes : s.name => s }
  provider = databricks.workspace
  name     = each.key
}

resource "databricks_secret" "this" {
  for_each = {
    for pair in flatten([
      for s in var.secrets.scopes : [
        for sec in s.secrets : { scope = s.name, key = sec.key, value = sec.value }
      ]
    ]) : "${pair.scope}:${pair.key}" => pair
  }
  provider     = databricks.workspace
  scope        = databricks_secret_scope.this[each.value.scope].name
  key          = each.value.key
  string_value = each.value.value
}
