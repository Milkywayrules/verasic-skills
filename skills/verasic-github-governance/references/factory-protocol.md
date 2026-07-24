# Factory protocol — new Verasic GitHub repo

Step-by-step bootstrap. Assumes **verasic-github-env** is wired when using `gh`.

Recommended entry: **verasic-github-governance-init** (`scripts/factory.sh`) — plan-first orchestrator that calls the steps below.

## Prerequisites

- [ ] Target org/account decided (Milkywayrules vs verasic-lab)
- [ ] Repo name + visibility: **private** (default)
- [ ] `gh` authenticated (`check-gh.sh` green)
- [ ] Skills installed: **verasic-github-governance**, **verasic-github-env**, **verasic-git-commits** (recommended)

## Step 1 — Create private repo

```bash
gh repo create ORG/REPO --private --confirm
git clone git@github.com:ORG/REPO.git && cd REPO
git checkout -b main 2>/dev/null || git checkout main
```

Do **not** enable branch protection in the GitHub UI on Free private plans — it will fail or mislead.

## Step 2 — Bootstrap templates + hooks

From repo root (adjust skill path if installed under `.agents/skills/`):

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh          # plan
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh --yes    # apply
```

Or manually:

```bash
bash .cursor/skills/verasic-github-governance/scripts/bootstrap-repo.sh
bash .cursor/skills/verasic-github-governance/scripts/wire-hooks.sh
lefthook install   # when lefthook is available
```

**Existing CI?** If `.github/workflows/` already has foreign workflows, bootstrap stops (exit 2). See `references/existing-repo-conflicts.md` and pass `--ci-strategy=skip|merge|replace`.

**Turborepo?** When `turbo.json` is at repo root, bootstrap installs `ci-turborepo.yml` (bun + turbo + gate job **`ci`**).

Expected artifacts:

- `.github/workflows/ci.yml` — stub or turborepo CI; job name **`ci`**
- `AGENTS.md` — governance block merged via markers
- `CONTRIBUTING.md`
- `.github/verasic-governance/hooks/pre-push` + `pre-commit`
- `lefthook.yml` — references repo-local governance hooks; `wire-hooks.sh` adds `commit-msg` when verasic-git-commits is installed
- `.github/pull_request_template.md` (optional brief)

## Step 3 — Initial commit + push (feature branch)

Never push directly to `main` after hooks are wired:

```bash
git checkout -b chore/governance-bootstrap
git add .
git commit -m "chore: bootstrap verasic governance templates"
git push -u origin chore/governance-bootstrap
gh pr create --title "chore: bootstrap governance" --body "Proves CI + merge path."
```

Or: `factory.sh --yes --open-pr`

## Step 4 — Prove CI / merge / Actions

- [ ] GitHub Actions run succeeds
- [ ] Job **`ci`** is green
- [ ] PR merges via merge commit or squash (per repo policy)
- [ ] Branch deleted on merge if repo setting enabled (OpenTofu baseline sets this when applied)

## Step 5 — Doctor

```bash
bash .cursor/skills/verasic-github-governance/scripts/doctor.sh
```

Exit `0` = soft governance ready.

## Step 6 — Hard protection (when plan allows)

1. Confirm eligibility: `references/plan-matrix.md`
2. For hard apply: use OpenTofu from a dogfood registry repo at `infra/github-governance/` ([public-free](https://github.com/Milkywayrules/verasic-github-governance-public-free) or [private-free](https://github.com/Milkywayrules/verasic-github-governance-private-free)) — product repos stay soft-only
3. Set `enable_hard_protection = true` in the appropriate example/root module
4. `tofu plan` / `tofu apply` with `TF_VAR_github_token` or `-var github_token=...`
5. Re-run doctor — plan-gated section should show hard protection configured

## Idempotent re-run

Safe to re-run:

- `bootstrap-repo.sh` — skips existing files unless `--force`; CI uses marker + `--ci-strategy`
- `wire-hooks.sh` — no-op when already wired
- `doctor.sh` — read-only
- `factory.sh` — plan by default; `--yes` applies

## Checklist summary

| # | Step | Done |
| --- | --- | --- |
| 1 | Private repo created | ☐ |
| 2 | Templates + hooks wired | ☐ |
| 3 | First PR from feature branch | ☐ |
| 4 | `ci` job green + merged | ☐ |
| 5 | Doctor exit 0 | ☐ |
| 6 | OpenTofu hard apply (if plan allows) | ☐ |
