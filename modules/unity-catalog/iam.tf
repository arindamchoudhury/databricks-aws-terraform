# Step 1: IAM role with placeholder ExternalId (real id comes from storage credential)
resource "aws_iam_role" "catalog_storage" {
  name = "${var.prefix}-catalog-storage"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::414351767826:root" }
      Action    = "sts:AssumeRole"
      Condition = { StringEquals = { "sts:ExternalId" = var.databricks_account_id } }
    }]
  })
}

resource "aws_iam_role_policy" "catalog_storage" {
  name = "${var.prefix}-catalog-storage-policy"
  role = aws_iam_role.catalog_storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject",
          "s3:PutObjectAcl", "s3:DeleteObject", "s3:ListBucket", "s3:GetBucketLocation",
        ]
        Resource = [aws_s3_bucket.catalog.arn, "${aws_s3_bucket.catalog.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-catalog-storage"]
      }
    ]
  })
}

# Step 3: patch trust policy with the real external_id from the storage credential
resource "time_sleep" "wait_for_storage_credential" {
  depends_on      = [databricks_storage_credential.this]
  create_duration = "20s"
}

resource "aws_iam_role" "catalog_storage_patched" {
  name = aws_iam_role.catalog_storage.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::414351767826:root" }
      Action    = "sts:AssumeRole"
      Condition = { StringEquals = { "sts:ExternalId" = databricks_storage_credential.this.aws_iam_role[0].external_id } }
    }]
  })
  depends_on = [time_sleep.wait_for_storage_credential]
  lifecycle { ignore_changes = [name] }
}
