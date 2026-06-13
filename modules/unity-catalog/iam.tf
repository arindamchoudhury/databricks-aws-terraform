# Step 1: create UC storage IAM role with account_id as placeholder external_id
resource "aws_iam_role" "uc_storage" {
  name = "${var.prefix}-uc-storage"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::414351767826:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.databricks_account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "uc_storage" {
  name = "${var.prefix}-uc-storage-policy"
  role = aws_iam_role.uc_storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = [
          aws_s3_bucket.metastore.arn,
          "${aws_s3_bucket.metastore.arn}/*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-uc-storage"]
      }
    ]
  })
}

# Step 2: after metastore_data_access is created, patch the trust policy with the real external_id
resource "time_sleep" "wait_for_uc_iam" {
  depends_on      = [databricks_metastore_data_access.this]
  create_duration = "20s"
}

# This updates the trust policy in-place once the real external_id is known
resource "aws_iam_role" "uc_storage_patched" {
  name = aws_iam_role.uc_storage.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::414351767826:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = databricks_metastore_data_access.this.aws_iam_role[0].external_id
          }
        }
      }
    ]
  })
  depends_on = [time_sleep.wait_for_uc_iam]
  lifecycle {
    ignore_changes = [name]
  }
}
