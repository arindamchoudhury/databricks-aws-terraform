data "aws_caller_identity" "current" {}

data "databricks_aws_crossaccount_policy" "this" {
  provider = databricks.mws
}

data "databricks_aws_assume_role_policy" "this" {
  provider    = databricks.mws
  external_id = var.databricks_account_id
}

resource "aws_iam_role" "cross_account" {
  name               = "${var.prefix}-databricks-crossaccount"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
}

resource "aws_iam_role_policy" "cross_account" {
  name   = "${var.prefix}-databricks-crossaccount-policy"
  role   = aws_iam_role.cross_account.id
  policy = data.databricks_aws_crossaccount_policy.this.json
}

# IAM propagation delay — Databricks validates the role immediately on credential creation
resource "time_sleep" "wait_for_iam" {
  depends_on      = [aws_iam_role_policy.cross_account]
  create_duration = "20s"
}
