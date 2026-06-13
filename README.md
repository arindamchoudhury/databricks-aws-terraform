# Databricks AWS Terraform

Production-quality Terraform deployment for Databricks on AWS — layered modules, isolated state per layer, S3 native locking (no DynamoDB).

## Architecture

Four state layers, deployed in order:

```
bootstrap  →  01-networking  →  02-workspace  →  03-unity-catalog
(S3 bucket)   (VPC, subnets)   (IAM, S3, MWS)   (UC metastore, catalog, grants)
```

Each layer (except bootstrap) stores its state in the S3 bucket created by bootstrap, using `use_lockfile = true` (Terraform 1.10+). No DynamoDB table required.

```
bootstrap/           — S3 state bucket (run once)
modules/
  networking/        — VPC, subnets, optional NAT gateway, security group
  workspace/         — Cross-account IAM role, root S3 bucket, MWS workspace
  unity-catalog/     — Auto-provisioned metastore lookup, catalog storage credential,
                       catalog with storage_root, bronze/silver/gold schemas and grants
environments/
  dev/
    01-networking/
    02-workspace/
    03-unity-catalog/
  prod/              — Same structure; prod CIDRs and workspace name differ
```

## Prerequisites

| Requirement | Notes |
|---|---|
| Terraform >= 1.15 | [install](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | `aws configure` — needs IAM permissions for VPC, IAM, S3 |
| Databricks account on AWS | `accounts.cloud.databricks.com` |
| Databricks service principal | See below |

**Service principal setup:**

1. Account console → **Settings → Identity and access → Service Principals → Add service principal**
2. Name it `terraform-deployer`; enable **Admin access** (workspace entitlement)
3. Account console → **User management → Service principals** → click `terraform-deployer` → **Roles** → assign **Account Admin**
4. Click **Secrets** → **Generate secret** — note the **Application Id** (`client_id`) and secret value (`client_secret`)

## Versions

| Component | Version |
|---|---|
| Terraform | `~> 1.15` |
| Databricks provider | `~> 1.117` |
| AWS provider | `>= 5.76, < 7.0` |
| VPC module | `~> 5.7` |
| Random provider | `~> 3.6` |
| Time provider | `~> 0.9` |

## Deployment

### 1. Bootstrap

```powershell
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit: set region and prefix (bucket name is auto-generated as <prefix>-databricks-tf-state-<random8hex>)

terraform init
terraform validate
terraform plan
terraform apply
```

Note the output `state_bucket_name` — you will need it in the next steps.

### 2. Networking

```powershell
cd environments/dev/01-networking
cp backend.tfvars.example backend.tfvars   # set bucket = <state_bucket_name from step 1>
cp terraform.tfvars.example terraform.tfvars

terraform init -backend-config="backend.tfvars"   # quotes required on PowerShell
terraform validate
terraform plan
terraform apply
```

### 3. Workspace

```powershell
cd environments/dev/02-workspace
cp backend.tfvars.example backend.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: databricks_account_id, databricks_client_id, databricks_client_secret, state_bucket

terraform init -backend-config="backend.tfvars"
terraform validate
terraform plan
terraform apply

terraform output workspace_url   # note for step 4
terraform output workspace_id    # note for step 4
```

### 4. Unity Catalog

```powershell
cd environments/dev/03-unity-catalog
cp backend.tfvars.example backend.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: credentials, workspace_url, workspace_id, admin_user

terraform init -backend-config="backend.tfvars"
terraform validate
terraform plan
terraform apply
```

Verify in the Databricks workspace:

```sql
SHOW CATALOGS;             -- includes "main"
SHOW SCHEMAS IN main;      -- bronze, silver, gold
SHOW GRANTS ON CATALOG main;
```

## Destroy (reverse order)

```powershell
# 03-unity-catalog first, then 02-workspace, then 01-networking
terraform -chdir=environments/dev/03-unity-catalog destroy
terraform -chdir=environments/dev/02-workspace destroy
terraform -chdir=environments/dev/01-networking destroy

# Only destroy bootstrap if you want to delete the state bucket itself
# (requires changing force_destroy = true in bootstrap/main.tf first)
```

## Key design decisions

**S3 native locking** — `use_lockfile = true` in each backend block. Terraform writes a `.tflock` object to S3 before any write. Eliminates the need for a DynamoDB table.

**Random bucket suffix** — bootstrap uses `random_id` (4 bytes = 8 hex chars) so the bucket name is globally unique without manual naming.

**Auto-provisioned metastore** — Databricks accounts created after Nov 2023 get one metastore per region automatically. The UC module looks it up via `data "databricks_metastores"` and assigns it to the workspace — it does not create one.

**Catalog-level storage** — the auto-provisioned metastore uses Databricks-managed S3 storage you cannot reference as `storage_root`. Instead, the module creates its own S3 bucket and wires it to the catalog via a `databricks_storage_credential` and `databricks_external_location`.

**Credential-before-role pattern** — `databricks_storage_credential` is created with a hardcoded role ARN string (not a Terraform resource reference). This breaks the circular dependency: the storage credential needs the IAM role ARN; the IAM role's trust policy needs the `external_id` from the storage credential. The `databricks_aws_unity_catalog_assume_role_policy` data source reads the real `external_id` after credential creation and generates the correct trust policy (including the required self-assume statement) for the IAM role — all in a single `apply` pass.

**NAT gateway off by default** — serverless compute (SQL warehouses, serverless jobs) runs in Databricks-managed infrastructure and never touches your VPC. Set `enable_nat_gateway = false` unless you use classic clusters. A NAT gateway costs ~$32/month idle.

**`time_sleep` resources** — three propagation delays are baked in:
- 20s after workspace cross-account IAM attachment (before `databricks_mws_credentials` validates the role)
- 30s after catalog IAM role trust policy update (before `databricks_external_location` validates the role)
- 15s after schema creation (before grants; Databricks' permissions API needs time to register new schemas)

## Security

- `terraform.tfvars` and `backend.tfvars` are in `.gitignore` — safe to store `databricks_client_secret` there
- The cross-account IAM role follows least-privilege (only the permissions Databricks requires for workspace management)
- All S3 buckets have public access blocked and AES256 encryption
- For production hardening: add Private Link endpoints, Customer-Managed KMS keys — see Ch 29 in the companion notes
