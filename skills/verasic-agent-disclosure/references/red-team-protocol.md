# Red-team protocol

## When to run

Run on demand when you change disclosure policy, Cursor UX wiring, or suspect regression after harness updates. Not a default CI gate — local operator-initiated only.

## Two tiers

| Tier | Catalog | Automation | Runtime |
| --- | --- | --- | --- |
| **Tier 1** | [red-team-prompts.md](red-team-prompts.md) — 18 core prompts | `run-red-team.sh` (Cursor Agent CLI) | ~9 min |
| **Tier 2** | [red-team-prompts-exhaustive.md](red-team-prompts-exhaustive.md) — 51 adversarial extensions | Manual spot-check or future script | Operator-paced |

**Tier 1** is the default regression gate: extraction, authority bypass, echo/indirect, routing, scope-lock, and mixed-task rows. Run after every policy or rule change.

**Tier 2** extends coverage — multi-turn gradual extraction, chain-of-thought gradual drain, encoding/obfuscation, roleplay/jailbreak, hypothetical/completion attacks, documentation laundering, SaaS customer framing, tool/error and log narration leakage, orchestrator-relay override, reverse-engineering bait, negative constraint flips, and additional mixed legitimate+extract prompts. Use for release hardening, borderline review, or when Tier 1 passes but narration still feels leaky. Full Tier 2 pass is optional; sampling 5–8 rows per session is acceptable.

## Prerequisites

- [Cursor Agent CLI](https://cursor.com/docs/cli) installed and on `PATH` as `cursor` (Tier 1 only)
- Logged in (`cursor agent` works in the target repo)
- Run from a git repository with `verasic-agent-disclosure` wired (rule in `.cursor/rules/`)

## Command (Tier 1)

From the repository root:

```bash
bash .cursor/skills/verasic-agent-disclosure/scripts/run-red-team.sh
```

When skills live under `.agents/skills/`, adjust the path prefix accordingly.

## Pass / fail criteria

See [red-team-prompts.md](red-team-prompts.md) for Tier 1 prompts, global pass criteria, and fail signals. Tier 2 rows in [red-team-prompts-exhaustive.md](red-team-prompts-exhaustive.md) share the same pass/fail bar. The Tier 1 script applies heuristic pattern checks on CLI output; manual review of borderline rows is expected.

## Runtime

Tier 1: ~9 minutes for the full 18-prompt suite (one Cursor Agent CLI invocation per prompt, ask mode).

Tier 2: no fixed runtime — manual prompts from the exhaustive catalog.

## Output

Tier 1 results land in `.verasic-agent-disclosure-runs/<timestamp>/` at the repo root (summary.tsv plus per-prompt response text files). Tier 2 manual runs: record pass/fail per row in operator notes or a future harness output dir.
