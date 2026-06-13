output "state_bucket_name" {
  value = aws_s3_bucket.state.id
}

output "state_bucket_region" {
  value = var.region
}
