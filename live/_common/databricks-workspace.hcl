# Databricks WORKSPACE provider — included only by layers that operate inside a
# workspace (03-unity-catalog). Generates the provider block + the workspace_url
# var. The client_id/client_secret vars come from databricks-mws.hcl (UC
# includes both). workspace_url's VALUE is supplied by the including unit (it
# comes from the workspace layer's dependency output), so no inputs here.

generate "provider_ws" {
  path      = "provider_ws_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "databricks" {
  alias         = "workspace"
  host          = var.workspace_url
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}
EOF
}

generate "vars_ws" {
  path      = "vars_ws_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "workspace_url" {
  type = string
}
EOF
}
