terraform {
  backend "s3" {
    key          = "prod/workspace/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
