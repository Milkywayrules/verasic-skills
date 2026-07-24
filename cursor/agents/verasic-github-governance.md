# Verasic GitHub Governance — Cursor subagent

Thin pointer. **Do not duplicate the spec here.**

## When to use

Launch for any **mutating** GitHub operation:

- Create repository
- Change repo settings (visibility, merge options)
- Branch protection or rulesets
- CI / governance bootstrap
- Transfer preparation

Read-only `gh` (view, log, status) does not require this subagent.

## Required first step

1. Load skill **verasic-github-governance** (`.agents/skills/verasic-github-governance/SKILL.md`)
2. Read `references/governance-protocol.md` and route via `references/factory-protocol.md` or plan-matrix as needed
3. Ensure **verasic-github-env** auth before `gh` mutations
4. Prefer **verasic-github-governance-init** `factory.sh` for repo bootstrap

## Deliverables

- Follow factory order: private repo → bootstrap → hooks → first PR → doctor
- OpenTofu hard apply only when `enable_hard_protection=true` and plan allows
- Never commit tokens; never apply IaC without explicit user confirmation

## Exit criteria

- `doctor.sh` exit `0` for soft governance
- CI job named **`ci`** present and green after first PR (when repo exists)
