# Databricks AWS Terraform (Terragrunt)

Layered Terraform for Databricks on AWS, orchestrated with **Terragrunt** — one copy of each module, environments expressed as thin units, cross-layer wiring via `dependency` blocks, S3 native locking (no DynamoDB).

## Architecture

State layers, deployed in order:

```
bootstrap  →  account/00-account  →  01-networking  →  02-workspace  →  03-unity-catalog
(S3 state)    (account users/         (VPC, subnets)    (cross-acct IAM,   (UC metastore,
              groups, once per                          root S3, MWS        catalog, schemas,
              Databricks account)                       workspace + admin   grants, secrets)
                                                        assignment)
```

- **bootstrap** is plain Terraform (it creates the state bucket Terragrunt then uses).
- **account/00-account** is applied **once per Databricks account** — account identities are global, so they don't belong to any single env.
- **01/02/03** are applied **per environment** (`dev`, `prod`), in dependency order, by `terragrunt run --all`.

Every layer stores state in the bootstrap bucket with `use_lockfile = true` (Terraform 1.10+). The state key is **derived automatically from each unit's path** (`account/00-account`, `dev/02-workspace`, …) by `live/root.hcl` — no per-unit backend config to keep in sync.

### Repository layout

```
bootstrap/                  — S3 state bucket (run once, plain Terraform)
modules/                    — reusable building blocks (one copy each)
  networking/               — VPC, subnets, optional NAT gateway, security group
  account-iam/              — account users (referenced) + groups (owned) + membership
  workspace/                — cross-account IAM role, root S3 bucket, MWS workspace,
                              workspace-scoped admin permission assignment
  unity-catalog/            — metastore lookup, storage credential + external location,
                              catalog with storage_root, bronze/silver/gold schemas + grants,
                              secret scopes/secrets (from secrets.json)
live/                       — Terragrunt orchestration
  root.hcl                  — S3 backend (path-derived key) + aws provider + common inputs
  _common/
    databricks-mws.hcl      — account (mws) provider + its credential variables
    databricks-workspace.hcl— workspace provider (Unity Catalog only)
  secrets.hcl.example       — template; copy to live/<scope>/secrets.hcl (gitignored)
  account/
    env.hcl                 — region, account id, state bucket (committed)
    secrets.hcl             — service-principal client_id/secret (gitignored)
    00-account/
      iam.json              — account users + groups (committed; no secrets)
      terragrunt.hcl
  dev/
    env.hcl                 — region, prefix, CIDRs, account id (committed)
    secrets.hcl             — service-principal client_id/secret (gitignored)
    01-networking/terragrunt.hcl
    02-workspace/terragrunt.hcl
    03-unity-catalog/
      terragrunt.hcl
      secrets.json          — UC secret values (gitignored, optional)
  prod/                     — same shape; prod region/prefix/CIDRs differ
```

There is **no duplicated HCL** between environments: the `.tf` lives once in `modules/`, and each env differs only in its `env.hcl` values, its gitignored `secrets.hcl`, and a ~20-line `terragrunt.hcl` per layer.

## Prerequisites

| Requirement | Notes |
|---|---|
| Terraform >= 1.15 | [install](https://developer.hashicorp.com/terraform/install) |
| Terragrunt >= 1.0 | [install](https://terragrunt.gruntwork.io/docs/getting-started/install/) — note the v1.0 `run --all` CLI |
| AWS CLI (authenticated) | needs IAM permissions for VPC, IAM, S3 |
| Databricks account on AWS | `accounts.cloud.databricks.com` |
| Databricks service principal | Account Admin; see below |

**Service principal setup:**

1. Account console → **Settings → Identity and access → Service Principals → Add service principal**
2. Account console → **User management → Service principals** → select it → **Roles** → assign **Account Admin**
3. **Secrets → Generate secret** — note the **Application Id** (`client_id`) and the secret value (`client_secret`)

## Versions

| Component | Version |
|---|---|
| Terraform | `~> 1.15` |
| Terragrunt | `>= 1.0` |
| Databricks provider | `~> 1.117` |
| AWS provider | `>= 5.76, < 7.0` |
| VPC module | `~> 5.7` |

## Deployment

### 1. Bootstrap (once, plain Terraform)

```powershell
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # set region and prefix
terraform init
terraform apply
terraform output state_bucket_name             # note this
```

### 2. Configure `live/`

For each scope you will deploy (`account`, `dev`, …):

- Set `state_bucket` and `databricks_account_id` in its `env.hcl` (committed, non-secret).
- Create its `secrets.hcl` from the template (gitignored):

```powershell
cp live/secrets.hcl.example live/account/secrets.hcl   # fill in client_id / client_secret
cp live/secrets.hcl.example live/dev/secrets.hcl
```

Credentials can also be supplied another way if you prefer — `secrets.hcl` is just the committed-safe default. AWS credentials come from your normal AWS CLI session.

### 3. Account IAM (once per Databricks account)

Edit `live/account/00-account/iam.json` (note: group names must **not** be the reserved `admins`/`users` — use e.g. `dbx-dev-admins`):

```json
{
  "users":  [ { "user_name": "you@example.com", "display_name": "You" } ],
  "groups": [ { "name": "dbx-dev-admins", "members": ["you@example.com"] } ]
}
```

```powershell
cd live/account
terragrunt run --all apply
```

### 4. An environment (networking → workspace → unity-catalog)

```powershell
cd live/dev
terragrunt run --all plan     # preview (downstream units show mock outputs until applied)
terragrunt run --all apply    # applies the three layers in dependency order
```

`run --all` reads the account layer's outputs (it's an external dependency), so **apply `live/account` before any env**. The workspace's `workspace_id`/`workspace_url` flow into Unity Catalog automatically via a `dependency` block — nothing to copy by hand.

Run a single layer instead with `cd live/dev/02-workspace; terragrunt apply`.

### Unity Catalog secrets (optional)

Create `live/dev/03-unity-catalog/secrets.json` (gitignored) before applying that layer:

```json
{ "scopes": [ { "name": "dev", "secrets": [ { "key": "my-api-key", "value": "…" } ] } ] }
```

If absent, scopes/secrets are simply not created (`fileexists()` guard). Read one in a notebook:

```python
api_key = dbutils.secrets.get(scope="dev", key="my-api-key")
```

### Verify

```sql
SHOW CATALOGS;             -- includes "main"
SHOW SCHEMAS IN main;      -- bronze, silver, gold
SHOW GRANTS ON CATALOG main;
```

## Destroy

```powershell
# An environment (reverse dependency order is handled by run --all)
cd live/dev
terragrunt run --all destroy

# Account IAM — only if you really mean to remove account-global groups
cd live/account
terragrunt run --all destroy
```

Destroying an environment removes its workspace, networking, and Unity Catalog — but **not** account users/groups (those live in the account layer; users are referenced, never deleted). Destroy `bootstrap` last, and only to delete the state bucket itself (set `force_destroy = true` first).

## Key design decisions

**Terragrunt, DRY units** — modules exist once; each env is value-only (`env.hcl` + `secrets.hcl` + thin `terragrunt.hcl`). Adding `staging` is a folder of small files, not a copied module.

**Path-derived state keys** — `live/root.hcl` sets the S3 key from `path_relative_to_include()` (normalized for Windows backslashes), so keys can't drift or collide.

**Generated providers** — modules are run as Terragrunt root units, so they declare no provider blocks. `root.hcl` generates the `aws` provider; `_common/databricks-mws.hcl` and `_common/databricks-workspace.hcl` generate the two Databricks providers (account + workspace) and their credential variables, included only by the layers that need them. (This is why the modules dropped `configuration_aliases`.)

**Account IAM at account scope** — account users/groups are global to the Databricks account, so they live in one `account/00-account` layer, not in each env. **Users are referenced** (`data "databricks_user"`) — never created or deleted by Terraform; they must pre-exist (console/SCIM). **Groups are owned** resources (`force = true` to adopt an existing same-named group). The workspace layer no longer manages IAM: it consumes `admin_group_id` from `dependency.account.outputs.group_ids[...]` and only creates the workspace-scoped `databricks_mws_permission_assignment`. So a workspace destroy never touches account identities.

**S3 native locking** — `use_lockfile = true`; Terraform writes a `.tflock` object before each write. No DynamoDB table.

**Auto-provisioned metastore** — accounts created after Nov 2023 get one metastore per region. The UC module looks it up via `data "databricks_metastores"` and assigns it to the workspace — it does not create one.

**Catalog-level storage** — the auto-provisioned metastore's Databricks-managed storage can't be used as `storage_root`, so the UC module creates its own S3 bucket and wires it via `databricks_storage_credential` + `databricks_external_location`.

**Credential-before-role pattern** — the storage credential is created with a hardcoded role ARN string (not a resource reference), breaking the circular dependency: the credential needs the role ARN; the role's trust policy needs the credential's `external_id`. `databricks_aws_unity_catalog_assume_role_policy` reads the real `external_id` afterward and builds the correct trust policy in one `apply`.

**Secrets handling** — Databricks SP creds live in gitignored `secrets.hcl` (template committed). UC secret values live in gitignored `secrets.json`. The UC `secrets` variable is **not** marked whole-object `sensitive` (that would break `for_each` over scope names); only each secret's `value` is wrapped with `sensitive()` at the point it's written.

**NAT gateway off by default** — serverless compute runs in Databricks-managed infrastructure and never touches your VPC. Keep `enable_nat_gateway = false` unless you run classic clusters (a NAT gateway is ~$32/month idle). For serverless-only you can drop networking entirely and use a Databricks-managed VPC.

**`time_sleep` propagation delays** — 20s after the workspace cross-account IAM attachment, 30s after the catalog role trust-policy update, 15s after schema creation (before grants).

## Security

- `secrets.hcl` and `secrets.json` are gitignored — never commit credentials or secret values; commit the `*.example` templates instead.
- `env.hcl` and `iam.json` are committed — they hold non-secret config (region, CIDRs, emails, group names).
- AWS credentials come from your AWS CLI session, not from any committed file.
- All S3 buckets block public access and use AES256 encryption; the cross-account IAM role is least-privilege.
- For production hardening: PrivateLink endpoints and customer-managed KMS keys — see Ch 29 in the companion notes.
```

