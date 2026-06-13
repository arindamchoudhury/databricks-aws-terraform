terraform {
  backend "s3" {
    key          = "dev/workspace/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
