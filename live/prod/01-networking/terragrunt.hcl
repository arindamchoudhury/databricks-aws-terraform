# Networking unit (prod). Identical to dev — only env.hcl values differ.
include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules/networking"
}

inputs = {
  vpc_cidr           = local.env.vpc_cidr
  private_subnets    = local.env.private_subnets
  public_subnets     = local.env.public_subnets
  availability_zones = local.env.availability_zones
  enable_nat_gateway = local.env.enable_nat_gateway
}
