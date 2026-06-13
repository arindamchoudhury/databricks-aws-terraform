variable "prefix" {
  type        = string
  description = "Short resource name prefix"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDRs for private subnets (at least 2)"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDRs for public subnets (NAT gateway)"
  default     = ["10.0.0.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs to use (must match or exceed number of subnets)"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Create a NAT gateway for classic cluster outbound access. Set false for serverless-only workspaces."
  default     = false
}
