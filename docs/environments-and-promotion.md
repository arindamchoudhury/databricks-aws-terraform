# Environments & Promotion Strategy

How we manage **dev → staging → prod** for Databricks on AWS: the branching model, how environments are expressed, and how changes are promoted. This is the decision record behind the repo layout.

## TL;DR

- **One `main` branch** (trunk-based). **No** `dev`/`staging`/`prod` branches.
- **Environments are directories** (Terraform/Terragrunt) **and DAB `targets`** — not branches.
- **Promote the *same commit* forward**: merge → staging, tag → prod. Never merge between long-lived env branches.
- **Dev is a freeform UI sandbox.** Git never deploys *to* dev; dev is where ideas originate and get *captured* into code.
- **Infra (this repo) and DABs (workloads) are separate repos** — different lifecycles.

## The three environments

| Env | Purpose | Who/what drives it |
|---|---|---|
| **dev** | Explore freely in the Databricks UI — notebooks, ad-hoc clusters, experiments | Humans, by hand. **Not** Git-driven. |
| **staging** | The captured work as **IaC + DABs**, deployed and **tested** | CI, on merge to `main` |
| **prod** | The validated release | CI, on a version tag |

The flow your work actually takes:

```
Explore in dev UI  →  author IaC/DAB on a feature branch  →  PR
      →  merge to main   →  CI deploys to STAGING  →  test
      →  git tag vX.Y.Z  →  CI deploys to PROD
```

The same commit is what reaches staging and then prod — promotion is "move this exact artifact forward," gated by **merge** and **tag**, not by merging code between environment branches.

## Why trunk-based, not branch-per-environment

The original instinct was `master`=dev, `staging` branch, `prod` branch. We deliberately did **not** do that:

- **Drift.** Long-lived env branches diverge; cherry-picking fixes between them is error-prone, and "what's actually in prod?" becomes ambiguous.
- **It fights DABs.** Databricks Asset Bundles express environments as `targets:` in one `databricks.yml`, not as branches. Branch-per-env duplicates that concept and pulls against the tool.
- **It fights the repo.** Environments are already directories here (`live/dev`, `live/prod`); adding a branch axis on top means two competing "which environment" dimensions that drift apart.
- **Dev doesn't map to a branch at all.** Dev is UI-freeform — nothing in Git controls it — so "a branch for dev" is a category error.

Trunk-based keeps one source of truth and makes promotion a property of *how far a commit has travelled*, not *which branch it lives on*.

## How environments are expressed

### Infrastructure — Terraform via Terragrunt (this repo)

Environments are **directories**; the `.tf` lives once in `modules/`, and each env differs only in values:

```
live/
  account/00-account/      # account-global IAM, applied once
  dev/   {01-networking, 02-workspace, 03-unity-catalog}
  prod/  {01-networking, 02-workspace, 03-unity-catalog}
  staging/ (to add — same shape as dev)
```

Each env has its own `env.hcl` (committed, non-secret) + `secrets.hcl` (gitignored). See [README.md](../README.md) for the full layout.

### Workloads — Databricks Asset Bundles (separate repo)

Jobs, notebooks, DLT pipelines live in DABs, with environments as **targets** in one `databricks.yml`:

```yaml
targets:
  dev:     { mode: development, workspace: { host: <dev-workspace-url> } }
  staging: { workspace: { host: <staging-workspace-url> } }
  prod:    { mode: production,  workspace: { host: <prod-workspace-url> } }
```

Deploy with `databricks bundle deploy -t staging`. The job is defined once; targets override only what differs. **DABs belong in their own repo** — workloads change far more often than infrastructure, and coupling them slows both.

## Capturing dev work into code

Dev is intentionally not Git-managed. To promote something built in the dev UI:

1. Build/iterate freely in the dev workspace.
2. Capture it as code on a **feature branch** — e.g. `databricks bundle generate` for a job/notebook, or author the Terraform/DAB by hand.
3. PR → merge to `main` → it deploys to **staging** for testing.
4. Tag a release → it deploys to **prod**.

## Environment parity — what's mirrored, what differs

"Keep the envs in sync" splits into three layers, each handled differently:

| Layer | How it stays in sync | What differs per env |
|---|---|---|
| **Structure** (resources, module logic) | One copy in `modules/`; envs are value files → parity is structural, not maintained | — |
| **Version** | Pin releases to a git **tag**; apply that tag to every env so none lags prod | — |
| **Env values** | n/a — intentionally different | region, prefix, CIDRs, workspace URL, state bucket |
| **IAM** | Shared **account group** for the envs that must match | which group each workspace grants |

So "mirror prod" = **same module shape (automatic) + same applied version (tag) + the same shared group** — *not* identical values. Region/CIDRs/URLs are what make them distinct envs.

### IAM: dev differs, staging == prod

Account users/groups are global to the Databricks account (one pool). The lever is **which group a workspace grants admin to**, set as `admin_group` in each `env.hcl`:

```hcl
# live/dev/env.hcl
admin_group = "dbx-dev-admins"   # dev's own admins — members may differ
# live/staging/env.hcl  AND  live/prod/env.hcl
admin_group = "dbx-admins"       # ONE shared group → staging and prod always match
```

The single account `iam.json` is the source of truth:

```json
"groups": [
  { "name": "dbx-dev-admins", "members": [ /* dev folks */ ] },
  { "name": "dbx-admins",     "members": [ /* shared staging+prod folks */ ] }
]
```

The workspace unit resolves it via the account dependency:
```hcl
admin_group_id = dependency.account.outputs.group_ids[local.env.admin_group]
```

Because staging and prod reference the **same** group, their admin membership is identical **by construction** — there is nothing to sync. Dev diverges simply by pointing at its own group. The same pattern extends to DAB grants later (dev → `dbx-dev-admins`, staging/prod → `dbx-admins`).

## Current status vs. target

| Piece | Status |
|---|---|
| Trunk-based, single `main` | ✅ done |
| Infra envs as directories (Terragrunt) | ✅ dev + prod live |
| Account IAM split into its own layer | ✅ done |
| **staging environment** | ❌ not built |
| **DABs repo + `targets`** | ❌ not started |
| **CI promotion** (merge→staging, tag→prod) | ❌ not built |
| Dev→code capture workflow | ❌ not operationalized |

We have built the **infrastructure foundation** (pillars 1–2). The **promotion engine** — staging, DABs, and the merge/tag CI flow — is the remaining work.

## Next steps

1. **Add `staging`** — copy the `live/dev` pattern (`env.hcl` + `secrets.hcl` + the three unit stubs) and add a `dbx-staging-admins` group to `live/account/00-account/iam.json`.
2. **Stand up the DABs repo** — `databricks.yml` with `dev`/`staging`/`prod` targets pointing at the three workspaces.
3. **Wire CI** — GitHub Actions: `terragrunt run --all apply` + `databricks bundle deploy` to staging on merge to `main`, to prod on tag.
