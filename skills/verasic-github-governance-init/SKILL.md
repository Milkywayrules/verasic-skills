---
name: verasic-github-governance-init
description: Confirm-first repo bootstrap for Verasic GitHub governance — plan-gated factory that runs bootstrap-repo, wire-hooks, lefthook install, and doctor. Requires verasic-github-governance and verasic-github-cli-init installed. Use when wiring governance into an existing or new repo, or when the user runs /verasic-github-governance-init.
disable-model-invocation: true
---

Security: see `references/scanner-notes.md` and upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md) for expected scanner signals and trust model.

# Verasic GitHub Governance Init — Factory Orchestrator

Source of truth for domain scripts: **verasic-github-governance** (`verasic-github-governance/references/factory-protocol.md`, `verasic-github-governance/references/existing-repo-conflicts.md`).

## Prerequisites

- **verasic-github-governance** installed (`.agents/skills/` or `.cursor/skills/`)
- **verasic-github-cli-init** installed (required for `--open-pr`)
- **verasic-git-commits-convention** recommended (commit-msg via wire-hooks)

Registered in verasic-init manifest as skill-only (`-|-`); factory requires explicit `--yes`. Install via `npx skills add Milkywayrules/verasic-skills` or bundle tag `@v0.2.4`.

## Orchestration (Cursor)

Bootstrap Verasic GitHub governance into this repo (plan-first factory).

Read `.cursor/skills/verasic-github-governance-init/SKILL.md` and `references/factory-protocol.md` on the governance skill, then run from the repository root:

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh
```

**Plan first** — relay the full stdout verbatim and ask the user to confirm before applying.

After confirmation:

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh --yes
```

If the repo already has foreign CI workflows, bootstrap may exit 2 — explain `references/existing-repo-conflicts.md` and ask which `--ci-strategy` (`skip`, `merge`, or `replace`) they want.

Optional after bootstrap proof:

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh --yes --open-pr
```

Requires **verasic-github-governance**, **verasic-github-cli-init**, and (recommended) **verasic-git-commits-convention** installed. Load github-cli-init env before any `gh` command. Never commit tokens.

Verify: `bash .cursor/skills/verasic-github-governance/scripts/doctor.sh` — required CI job name **`ci`**.

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

4. If bootstrap exits `2`, read `verasic-github-governance/references/existing-repo-conflicts.md` and pick `--ci-strategy=skip|merge|replace`.

## Flags

| Flag | Effect |
| --- | --- |
| `--yes` | Apply (default is plan-only) |
| `--force` | Pass `--force` to bootstrap-repo.sh |
| `--ci-strategy=` | `skip`, `merge`, or `replace` |
| `--open-pr` | Branch `chore/governance-bootstrap`, commit, push, `gh pr create` |

## Hard rules

- **Never run `--yes` without user confirmation.**
- Never commit tokens; load via verasic-github-cli-init before `gh`.
- Required CI job name remains **`ci`**.
