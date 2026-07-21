# verasic-fusion — helper

Multi-model fusion for exploration and decision support. Same question, several
models, one orchestrated answer.

## Required every run

```text
mode: verbatim | fusion | verbatim+fusion
models: <comma-separated model slugs, minimum 2>
<your question>
```

No default models. No default mode. Missing fields → the agent asks before spawning.

## Optional

```text
template: <slug>
acknowledge: proceed with N models    # only when roster exceeds hard cap (6)
```

## Roster caps

- **4+ models** — warning (cost/latency)
- **6+ models** — blocked unless you acknowledge

## Templates

| Slug                    | Use                                         |
| ----------------------- | ------------------------------------------- |
| `board-verdict`         | BOD yes/no vote                             |
| `rfc-review`            | Spec / proposal review                      |
| `tradeoff-matrix`       | Option comparison with matrix               |
| `brief-research`        | Multi-model opinion brief — not `verasic-deep-research` ledger |
| `risk-register`         | Risk table + priorities                     |
| `devils-advocate`       | Argue against the proposal                  |
| `premortem`             | Assume failure, work backward               |
| `stakeholder-lens`      | Per-model stakeholder (requires `lens-map`) |
| `compare-to-status-quo` | Change vs inaction                          |

Omit `template` for generic core skeleton only.

**Renamed:** `research-brief` → `brief-research`. If you pass the old slug, the agent asks
you to use `brief-research`.

## Example

```text
/verasic-fusion
mode: fusion
models: composer-2.5-fast, gemini-3-flash, claude-sonnet-5-thinking-high
template: board-verdict

Should teams adopt short-lived feature flags for all production releases?
```

## Example — stakeholder-lens

```text
mode: fusion
models: composer-2.5-fast, claude-opus-4-8-thinking-medium, gpt-5.6-sol-medium
template: stakeholder-lens
lens-map:
  composer-2.5-fast: ceo
  claude-opus-4-8-thinking-medium: cto
  gpt-5.6-sol-medium: customer

How should we price the MVP?
```

## Output modes

| Mode              | You get                               |
| ----------------- | ------------------------------------- |
| `verbatim`        | Each model's answer unchanged         |
| `fusion`          | Synthesized sections + recommendation |
| `verbatim+fusion` | Verbatim blocks first, then synthesis |

## Scope

Readonly exploration only — no file edits, commits, or deploys.

## Models

See `references/models.md` for known slugs. Unavailable models are reported before
spawn — fix the roster or pick substitutes.

## Degraded

If subagents cannot spawn, the agent asks before running sequential single-context
fusion (not parallel).
