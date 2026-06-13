terraform {
  backend "s3" {
    key          = "dev/unity-catalog/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
