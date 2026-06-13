# Databricks AWS Terraform

Production-quality Terraform deployment for Databricks on AWS — layered modules, isolated state per layer, S3 native locking (no DynamoDB).

## Architecture

Three state layers per environment, deployed in order:

```
01-networking  →  02-workspace  →  03-unity-catalog
(VPC, subnets)    (IAM, S3, MWS)   (metastore, catalog, grants)
```

Each layer stores state in S3 with `use_lockfile = true` (Terraform 1.10+). No DynamoDB table needed.

## Prerequisites

- Terraform >= 1.15 ([install](https://developer.hashicorp.com/terraform/install))
- AWS CLI configured (`aws configure`) with permissions to create VPCs, IAM roles, S3 buckets
- Databricks account on AWS (accounts.cloud.databricks.com)
- Databricks service principal with **Account Admin** role
  - Create at: Accounts console → Settings → Service Principals → Add

## Versions

| Component | Version |
|---|---|
| Terraform | ~> 1.15 |
| Databricks provider | ~> 1.117 |
| AWS provider | >= 5.76, < 7.0 |
| VPC module | ~> 5.7 |

## Layout

```
bootstrap/           — S3 state bucket (one-time)
modules/
  networking/        — VPC, subnets, NAT gateway, security group
  workspace/         — Cross-account IAM, root S3, MWS workspace
  unity-catalog/     — Metastore, UC IAM, catalog, schemas, grants
environments/
  dev/
    01-networking/
    02-workspace/
    03-unity-catalog/
  prod/              — Same structure; prod CIDRs and workspace name differ
```

## First-Time Deployment

### 1. Bootstrap the state bucket

```powershell
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set state_bucket_name to a globally unique value
terraform init
terraform apply
terraform output state_bucket_name   # note this value
```

### 2. Deploy dev networking

```powershell
cd environments/dev/01-networking
cp backend.tfvars.example backend.tfvars
# Edit backend.tfvars: set bucket to the value from step 1
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.tfvars
terraform apply
```

### 3. Deploy dev workspace

```powershell
cd environments/dev/02-workspace
cp backend.tfvars.example backend.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: databricks_account_id, databricks_client_id, state_bucket
$env:TF_VAR_databricks_client_secret = "your-service-principal-secret"
terraform init -backend-config=backend.tfvars
terraform apply
terraform output workspace_url    # note for next step
terraform output workspace_id     # note for next step
```

### 4. Deploy dev Unity Catalog

```powershell
cd environments/dev/03-unity-catalog
cp backend.tfvars.example backend.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: fill in workspace_url and workspace_id from step 3
$env:TF_VAR_databricks_client_secret = "your-service-principal-secret"
terraform init -backend-config=backend.tfvars
terraform apply
```

## Destroy (reverse order)

```powershell
# Run terraform destroy in: 03-unity-catalog → 02-workspace → 01-networking
```

## Security Notes

- Never commit `terraform.tfvars` or `backend.tfvars` — they are in `.gitignore`
- Pass `databricks_client_secret` via environment variable (`TF_VAR_databricks_client_secret`), not in tfvars files
- For production, consider adding Private Link (see Ch 29 §SRA in the book)
