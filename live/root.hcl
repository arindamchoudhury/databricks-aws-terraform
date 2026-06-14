# Root Terragrunt config — included by EVERY unit. Holds only what is common to
# all layers: the S3 backend, the AWS provider, and the inputs every module
# takes (region, prefix). Databricks providers are layer-specific and live in
# live/_common/databricks-*.hcl (included only by the layers that need them).

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

# Backend: bucket/region from env.hcl; state KEY derived from the unit's path
# relative to this root, so it can never drift or collide. replace() normalizes
# Windows backslashes so the S3 key is always /-separated.
#   live/dev/02-workspace -> dev/02-workspace/terraform.tfstate
remote_state {
  backend = "s3"
  generate = {
    path      = "backend_generated.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = local.env.state_bucket
    key          = "${replace(path_relative_to_include(), "\\", "/")}/terraform.tfstate"
    region       = local.env.region
    encrypt      = true
    use_lockfile = true
  }
}

generate "provider_aws" {
  path      = "provider_aws_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.region
}
EOF
}

# Inputs every module declares.
inputs = {
  region = local.env.region
  prefix = local.env.prefix
}
