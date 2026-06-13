output "vpc_id" {
  value = module.networking.vpc_id
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "security_group_ids" {
  value = module.networking.security_group_ids
}

output "vpc_cidr" {
  value = module.networking.vpc_cidr
}
