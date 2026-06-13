terraform {
  backend "s3" {
    key          = "prod/networking/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
