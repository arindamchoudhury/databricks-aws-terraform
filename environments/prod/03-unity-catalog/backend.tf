terraform {
  backend "s3" {
    key          = "prod/unity-catalog/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
