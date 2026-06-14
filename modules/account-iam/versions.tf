terraform {
  required_version = ">= 1.10"
  required_providers {
    # aws is declared only because root.hcl generates an aws provider block for
    # every unit; this layer creates no AWS resources.
    aws = {
      source = "hashicorp/aws"
    }
    databricks = {
      source = "databricks/databricks"
    }
  }
}
