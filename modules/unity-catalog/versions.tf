terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    # Provider blocks (incl. the mws + workspace aliases) are supplied by the
    # Terragrunt-generated providers file in live/root.hcl, so this is a root
    # unit — no configuration_aliases (which are only for child modules).
    databricks = {
      source = "databricks/databricks"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
