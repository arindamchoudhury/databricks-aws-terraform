terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    # Provider blocks (incl. the mws alias) come from the Terragrunt-generated
    # files in live/_common/databricks-mws.hcl — this is a root unit, so no
    # configuration_aliases (which are only for child modules).
    databricks = {
      source = "databricks/databricks"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
