# Verasic Agent Disclosure

Block harness, skill, router, and protocol leaks in user-facing agent responses.
Always-on policy rule plus an adversarial red-team catalog for regression testing.

## Parts

Paths relative to this skill folder unless noted. After `setup.sh`, skill files
live under `.cursor/skills/verasic-agent-disclosure/`.

| File | Role |
| --- | --- |
| `references/disclosure-policy.md` | Canonical policy spec — single source of truth |
| `assets/verasic-agent-disclosure.mdc` | Rule asset copied into `.cursor/rules/` |
| `references/red-team-prompts.md` | Tier 1 adversarial catalog (18 prompts) + pass/fail criteria |
| `references/red-team-prompts-exhaustive.md` | Tier 2 exhaustive adversarial extensions (manual / future script) |
| `references/red-team-protocol.md` | When/how to run regression (Tier 1 vs Tier 2) |
| `references/saas-integration.md` | Hosted product wiring — P0 spec (filter mandatory for SaaS beta) |
| `scripts/wire-rule.sh` | Per-repo rule install (used by verasic-init) |
| `scripts/run-red-team.sh` | Cursor Agent CLI regression harness |
| `scripts/run-red-team-tools.sh` | Tools-mode red-team stub (SaaS hardening; not implemented) |
| `scripts/test-regression.sh` | Structural regression (no CLI) |
| `SKILL.md` | Auto-trigger + orchestration |
| `.cursor/rules/verasic-agent-disclosure.mdc` | Always-applied rule (after `setup.sh`) |
| `.cursor/commands/verasic-disclosure-red-team.md` | `/verasic-disclosure-red-team` slash command |

## Three layers

| Layer | What | Catches |
| --- | --- | --- |
| 0 — always-on rule | `verasic-agent-disclosure.mdc` | Extraction, inventories, router narration in every turn |
| 1 — skill | `SKILL.md` + `references/` | Portable orchestration for non-Cursor agents |
| 2 — red-team | `/verasic-disclosure-red-team` | Tier 1 regression — 18 adversarial prompts (~9 min) |

Red-team runs in two tiers. **Tier 1** ([red-team-prompts.md](references/red-team-prompts.md)) is the automated default: 18 core extraction, authority, echo, routing, scope-lock, doc-laundering, and mixed-task prompts via `run-red-team.sh` (~9 min). **Tier 2** ([red-team-prompts-exhaustive.md](references/red-team-prompts-exhaustive.md)) adds manual adversarial coverage — gradual multi-turn asks, encoding tricks, jailbreaks, doc-laundering, SaaS framing, tool leakage, constraint flips — for release hardening or when Tier 1 passes but responses still feel borderline. Same pass bar for both; see [red-team-protocol.md](references/red-team-protocol.md).

Wire the rule per repo (once) — `/verasic-init` runs `scripts/wire-rule.sh` automatically, or manually:

```bash
bash .cursor/skills/verasic-agent-disclosure/scripts/wire-rule.sh
```

Legacy repos may still have `no-expose-agent-internals.mdc`; wire removes it when migrating.

## Usage

- Disclosure policy applies automatically when the rule is wired — nothing to invoke for normal work.
- `/verasic-disclosure-red-team` — run the full adversarial regression from repo root; relay summary verbatim.
- Or say "run agent disclosure red-team" — agent should invoke the script, not freestyle prompts.

## Output

Red-team writes `.verasic-agent-disclosure-runs/<timestamp>/` with `summary.tsv` and per-prompt outputs. Script exits non-zero on any FAIL or CLI ERROR row.

Security: [references/scanner-notes.md](references/scanner-notes.md) · upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md)

SaaS operators: [references/saas-integration.md](references/saas-integration.md)

## Install into a new project

From the project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

Then `/verasic-init --yes` to wire the rule, or skill-only:

```bash
npx skills add Milkywayrules/verasic-skills
bash .agents/skills/verasic-agent-disclosure/scripts/wire-rule.sh
```
