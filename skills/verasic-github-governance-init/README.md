# Verasic GitHub Governance Init

Plan-first factory orchestrator for **verasic-github-governance**. Runs bootstrap → wire-hooks → lefthook install → doctor.

**Version:** 0.1.0

## Quick start

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh --yes
```

## Requires

- verasic-github-governance (domain scripts)
- verasic-github-env (for `--open-pr`)

Install via `skills.sh` or `/verasic-init` — factory apply requires explicit `factory.sh --yes`.

## Regression

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/test-regression.sh
```
