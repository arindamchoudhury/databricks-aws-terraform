module "networking" {
  source = "../../../modules/networking"

  prefix             = var.prefix
  region             = var.region
  vpc_cidr           = var.vpc_cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  availability_zones = var.availability_zones
}
