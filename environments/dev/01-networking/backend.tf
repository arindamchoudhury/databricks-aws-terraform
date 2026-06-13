terraform {
  backend "s3" {
    key          = "dev/networking/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
