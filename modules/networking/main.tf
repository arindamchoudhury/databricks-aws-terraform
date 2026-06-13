module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.7"

  name = "${var.prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = true
  create_igw           = var.enable_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  default_security_group_egress = [
    {
      cidr_blocks = "0.0.0.0/0"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound"
    }
  ]

  default_security_group_ingress = [
    {
      self        = true
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow inbound from cluster nodes"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = var.prefix
  }
}
