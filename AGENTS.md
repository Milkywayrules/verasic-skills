# AGENTS — editing verasic-skills

Guidance for AI agents and maintainers working in this repository.

## Skills-first Cursor UX (v0.2.0+)

- **Orchestration lives in `skills/*/SKILL.md`** — slash entries come from skill folder names, not `cursor/commands/`.
- **`cursor/` ships subagents and rules only** — 4 agents + 4 rules; see [references/verasic-cursor-map.md](references/verasic-cursor-map.md).
- **Canonical slash map:** [references/verasic-cursor-map.md](references/verasic-cursor-map.md) — do not duplicate the table in README or skill docs; link it.
- Workflow skills set `disable-model-invocation: true` in SKILL frontmatter (except `verasic-git-commits-convention`, which is rule-driven).

## Namespace (manifest skills)

| Skill folder | Role |
| --- | --- |
| `verasic-github-cli-init` | GitHub CLI auth bootstrap |
| `verasic-github-governance` | CI, hooks, doctor, governance spec |
| `verasic-github-governance-init` | Plan-first governance factory |
| `verasic-git-commits-convention` | Commit message spec + hook |
| `verasic-git-commits-audit` | Pre-push history audit |
| `verasic-agent-disclosure` | Disclosure policy + red-team |
| `verasic-bugbot` | Local bug-style code review |
| `verasic-secbot` | STRIDE security review |
| `verasic-fusion` | Multi-model fusion |
| `verasic-deep-research` | Ledger-backed research |
| `verasic-init` | Repo wiring orchestrator |

**Removed in v0.2.0:** `verasic-config` (no repo config skill; secbot uses inlined defaults). Centralized config may return as package-oriented tooling — **TBD, not built today** — see [references/cursor-skills-ux.md](references/cursor-skills-ux.md).

## Before you ship changes

1. Run regressions for touched skills: `bash skills/<name>/scripts/test-regression.sh`
2. Refresh integrity after `VERSION` or `integrity.txt` edits: `bash scripts/refresh-integrity.sh <name>` or `--all`
3. Run repo gates: `bash scripts/test-all.sh`
4. Grep retired names (see CHANGELOG v0.2.1) — zero hits outside CHANGELOG / ADR retired lists

## Reference docs

| Doc | Purpose |
| --- | --- |
| [references/verasic-cursor-map.md](references/verasic-cursor-map.md) | Slash → skill → subagent → rule |
| [references/verasic-naming.md](references/verasic-naming.md) | Naming grammar |
| [references/cursor-skills-ux.md](references/cursor-skills-ux.md) | Skills-first UX model |
| [references/adr/0001-cursor-ux-skills-first.md](references/adr/0001-cursor-ux-skills-first.md) | ADR: why skills-first |
| [references/cursor-custom-subagents.md](references/cursor-custom-subagents.md) | Standalone model-pinned subagents (observed) |
| [references/adr/0002-cursor-custom-subagents.md](references/adr/0002-cursor-custom-subagents.md) | ADR: standalone subagent layout |
| [references/release-protocol.md](references/release-protocol.md) | Version + tag checklist |
| [references/repo-meta.md](references/repo-meta.md) | GitHub settings for maintainers |

## Conventions

- Match existing skill structure: `SKILL.md`, `references/`, optional `scripts/`, `integrity.txt` + `integrity.sha256`.
- Register wiring in `skills/verasic-init/manifest.txt` and sync `versions.lock` entry order.
- Update `skills/verasic-init/references/skill-ux-map.txt` when cursor agents/rules change.
- Do not reintroduce `cursor/commands/` or backward-compat aliases for retired slash names.
