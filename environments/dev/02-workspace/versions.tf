terraform {
  required_version = "~> 1.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.76, < 7.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.117"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
