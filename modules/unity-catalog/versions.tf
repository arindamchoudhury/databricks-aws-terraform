terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.mws, databricks.workspace]
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
