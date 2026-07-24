---
name: verasic-github-governance-init
description: Confirm-first repo bootstrap for Verasic GitHub governance — plan-gated factory that runs bootstrap-repo, wire-hooks, lefthook install, and doctor. Requires verasic-github-governance and verasic-github-env installed. Use when wiring governance into an existing or new repo, or when the user runs /verasic-governance-factory.
---

Security: see upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md).

# Verasic GitHub Governance Init — Factory Orchestrator

Source of truth for domain scripts: **verasic-github-governance** (`references/factory-protocol.md`, `references/existing-repo-conflicts.md`).

## Prerequisites

- **verasic-github-governance** installed (`.agents/skills/` or `.cursor/skills/`)
- **verasic-github-env** installed (required for `--open-pr`)
- **verasic-git-commits** recommended (commit-msg via wire-hooks)

Registered in verasic-init manifest as skill-only (`-|-`); factory requires explicit `--yes`.

## Workflow

1. **Plan first (default)** — from repo root:

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh
```

2. **Relay the plan** — show stdout, explain steps, ask confirmation before `--yes`.

3. **Apply after confirmation**:

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh --yes
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh --yes --ci-strategy=skip
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh --yes --open-pr
```

4. If bootstrap exits `2`, read `existing-repo-conflicts.md` and pick `--ci-strategy=skip|merge|replace`.

## Flags

| Flag | Effect |
| --- | --- |
| `--yes` | Apply (default is plan-only) |
| `--force` | Pass `--force` to bootstrap-repo.sh |
| `--ci-strategy=` | `skip`, `merge`, or `replace` |
| `--open-pr` | Branch `chore/governance-bootstrap`, commit, push, `gh pr create` |

## Hard rules

- **Never run `--yes` without user confirmation.**
- Never commit tokens; load via verasic-github-env before `gh`.
- Required CI job name remains **`ci`**.
