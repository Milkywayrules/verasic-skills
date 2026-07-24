# Verasic GitHub Governance

Soft-first GitHub repo governance for Verasic: CI bootstrap, lefthook hooks, doctor checks, and plan-gated hard protection via OpenTofu.

**Version:** 1.1.0

## Parts

Paths relative to this skill folder unless noted.

| File | Role |
| --- | --- |
| `references/governance-protocol.md` | Model, mutation routing, enforcement layers |
| `references/factory-protocol.md` | New-repo bootstrap checklist |
| `references/existing-repo-conflicts.md` | CI conflict detection and `--ci-strategy` |
| `references/plan-matrix.md` | Free vs Team — branch protection eligibility |
| `scripts/bootstrap-repo.sh` | Copy templates into repo (idempotent; CI conflict exit 2) |
| `scripts/wire-hooks.sh` | Wire lefthook / detect manual steps |
| `scripts/doctor.sh` | Soft readiness (`0`) vs gaps (`2`) |
| `scripts/test-regression.sh` | Smoke tests (local) |
| `templates/` | CONTRIBUTING, CI, turborepo CI, AGENTS block, lefthook, PR template |
| `hooks/pre-push` | Block direct default-branch push |
| `hooks/pre-commit` | Default-branch reminder |
| `SKILL.md` | Auto-trigger + orchestration |

Orchestrator: **verasic-github-governance-init** (`factory.sh`) — plan-first wrapper around bootstrap + hooks + doctor.

OpenTofu hard rules live in dogfood registry repos at `infra/github-governance/` — [public-free](https://github.com/Milkywayrules/verasic-github-governance-public-free) (hard path) and [private-free](https://github.com/Milkywayrules/verasic-github-governance-private-free) (soft path). Product repos use soft governance only; do not copy IaC.

## Quick start

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh --yes
```

Or manually:

```bash
bash .cursor/skills/verasic-github-governance/scripts/bootstrap-repo.sh
bash .cursor/skills/verasic-github-governance/scripts/wire-hooks.sh
lefthook install
bash .cursor/skills/verasic-github-governance/scripts/doctor.sh
```

## CI conflict (existing repos)

```bash
bash .cursor/skills/verasic-github-governance/scripts/bootstrap-repo.sh --ci-strategy=skip
bash .cursor/skills/verasic-github-governance/scripts/bootstrap-repo.sh --ci-strategy=replace
```

See `references/existing-repo-conflicts.md`.

## Doctor exit codes

| Code | Meaning |
| --- | --- |
| `0` | Soft governance ready |
| `2` | Missing CI, CONTRIBUTING, hooks, or `ci` job name |
| `1` | Not a git repo / broken install |

Bootstrap also uses exit `2` for foreign CI conflicts.

## CI job name

The workflow job **must** be named `ci` — matches future required status checks and OpenTofu branch protection.

## Regression

```bash
bash .cursor/skills/verasic-github-governance/scripts/test-regression.sh
```

Security: [references/scanner-notes.md](references/scanner-notes.md) · upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md)
