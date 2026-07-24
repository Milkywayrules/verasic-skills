# Scanner notes — verasic-github-governance-init

## Why scanners may flag this skill

- **Factory orchestrator** — `scripts/factory.sh` chains bootstrap, hook wiring, lefthook install, and doctor from sibling **verasic-github-governance**.
- **Git / CI mutations (with `--yes`)** — Applies governance templates and may open a PR when `--open-pr` is passed.
- **Inherited harness signals** — Installers score the bundle; governance hook wiring and CI bootstrap patterns surface here too.

## Mitigations

- **Confirm-first default** — Without `--yes`, factory prints a plan only; no repo mutations.
- **No secrets in skill** — Tokens load via **verasic-github-env** at runtime; not embedded in scripts.
- **Sibling source of truth** — Domain protocols live in **verasic-github-governance**; this skill orchestrates only.
- **Explicit `--open-pr`** — GitHub writes require env auth and user confirmation.

See upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md).
