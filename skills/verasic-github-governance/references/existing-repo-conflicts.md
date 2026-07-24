# Existing repo conflicts — CI and templates

When bootstrapping governance into a repo that already has GitHub Actions workflows, `bootstrap-repo.sh` detects foreign workflows and stops unless you choose a strategy.

## Marker

Workflows installed or updated by this skill include a YAML comment:

```yaml
# verasic-governance-ci: managed
```

That marker means the file is safe to update with `--ci-strategy=merge` or default re-run (when managed).

## Conflict tiers

| Tier | Condition | Default behavior | Resolution |
| --- | --- | --- | --- |
| **Greenfield** | No `.github/workflows/*.yml` | Write CI template | None |
| **Managed** | At least one workflow contains the marker | Update managed `ci.yml` (or turborepo template when `turbo.json` exists) | Re-run bootstrap; use `--force` for non-CI files |
| **Foreign** | Workflows exist without the marker | **Exit 2** — stop | Pass `--ci-strategy` (see below) |

## `--ci-strategy` values

| Strategy | CI behavior | When to use |
| --- | --- | --- |
| *(default)* | Stop on foreign workflows (exit 2) | First run on repos with existing CI — forces an explicit choice |
| `skip` | Do not add or change workflows | Repo already has production CI; only wire hooks / CONTRIBUTING |
| `merge` | Update only files that already contain the marker | Refresh a previously bootstrapped repo |
| `replace` | Overwrite `.github/workflows/ci.yml` with the governance template | Accept replacing the main CI file (standard or turborepo) |

## Turborepo detection

When `turbo.json` exists at the repo root, templates use `ci-turborepo.yml` (bun + turbo lint/typecheck/test/build + gate job **`ci`**). Otherwise the minimal stub `ci.yml` is used.

## AGENTS.md merge

`AGENTS.md` is merged using HTML comment markers:

```html
<!-- verasic-governance:start -->
...
<!-- verasic-governance:end -->
```

If the block is missing, bootstrap appends it. If present, bootstrap skips unless `--force` (then refreshes the block only).

## Other templates

`CONTRIBUTING.md`, `lefthook.yml`, and `.github/pull_request_template.md` remain **copy-if-missing** (or `--force` overwrite). They do not participate in CI conflict detection.

## Related

- Factory checklist: `factory-protocol.md`
- Init orchestrator: **verasic-github-governance-init** (`scripts/factory.sh`)
