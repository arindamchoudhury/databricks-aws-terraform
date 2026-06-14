# Account-scope values. Databricks account IAM is global (shared by dev + prod),
# so this layer is applied ONCE — it is not under dev/ or prod/.
locals {
  region                = "eu-central-1"
  prefix                = "dbx" # account scope; not env-specific
  state_bucket          = "arindam-databricks-tf-state-dd660bdc"
  databricks_account_id = "6d1f36bc-6560-40ce-a6ca-84a9ba7ecce5"
}
