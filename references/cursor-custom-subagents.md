# Cursor custom subagents (observed)

Empirical mechanics for **standalone model-pinned subagents** in this repo. May differ from [official subagent docs](https://cursor.com/docs/subagents.md). Decisions: [ADR 0002](adr/0002-cursor-custom-subagents.md). Frozen tables: [snapshot 2026-07-25](snapshots/cursor-custom-subagents-2026-07-25.md).

## Scope

| Path | Role |
| --- | --- |
| `etc/cursor/agents/` | **Source** — generic `subagent-*` roster (this doc) |
| `cursor/agents/` | **Product** — `verasic-*` only; init/manifest |
| `.cursor/agents/` | **Runtime** — Cursor Task reads here; manual copy from `etc/` |

Not in skills.sh product. No verasic-init wiring in v1.

## Two knobs

| Knob | Effect |
| --- | --- |
| **`subagent_type`** | Which agent file / system prompt (`name:` in frontmatter) |
| **Task `model` (optional)** | Flat-slug override; stricter allowlist than frontmatter |

**Override beats frontmatter** when both are set.

## Two model resolution paths

| Path | Where | Observed |
| --- | --- | --- |
| **Frontmatter** | `model:` in agent file | Accepts roster flat slugs; bracket syntax works in frontmatter (not shipped in Phase 1) |
| **Task inline** | Task tool `model` param | Flat slugs only; bracket **hard reject**; error allowlist is **incomplete subset** |

## Session behavior

- **New agent files** added to `.cursor/agents/` → not in Task enum until **new chat** (enum frozen at session start).
- **Frontmatter edits** on an already-registered agent → live on next spawn.
- **Invalid `subagent_type`** → tool-level enum reject before spawn.

## Spawn rules (orchestrator)

| Pattern | Result |
| --- | --- |
| Exact `subagent_type: subagent-<name>` | ✓ preferred |
| Task `model` flat override | ✓ when slug on inline allowlist (see snapshot) |
| `gemini-3.6-flash-low` / `-medium` inline | ✗ hard reject — use dedicated subagent file |
| Bracket in Task `model` | ✗ hard reject |
| `composer-2.5` (non-fast) inline | ✗ hard reject |
| Fuzzy labels (“grok high”) | ✗ |
| `model: subagent-*` (name as model) | Unreliable — do not use |

## Runtime workflow

```bash
cp etc/cursor/agents/*.md .cursor/agents/
```

Then **start a new chat** before Task dispatch picks up new names.

## Agent file template

```markdown
---
name: subagent-example
description: Generic worker on <slug>. Parent assigns the task verbatim.
model: <flat-slug>
---

The parent agent delegates work to you. The parent's prompt is the full task — execute it as given and return your output to the parent.
```

Gemini low/medium: add to `description:` — `Spawn via subagent_type only; Task inline model override not supported.`

## Bracket syntax (advanced, not Phase 1)

Official docs support parametric frontmatter, e.g. `claude-opus-5[effort=high,context=300k]`. Use when no flat slug matches the desired config. **Never** in Task inline `model`. Phase 1 roster uses flat slugs only (all validated on account 2026-07-25).

## PoC transcript index

Short IDs in the table are Cursor chat-transcript handles (resolvable in Cursor only), not repo paths.

| ID | Proved |
| --- | --- |
| [f5071ca5](f5071ca5-f474-4b69-9f3e-b7c58e688dd3) | PoC workflow; `subagent_type` vs wrong inline/generalPurpose |
| [ab70e1ae](ab70e1ae-4f22-4631-a469-012033adfb48) | Task enum; global→project sync |
| [6da67d61](6da67d61-4c76-4738-8f58-0827b259052f) | terra-low-fast; catalog listing |
| [d3686c95](d3686c95-2388-40f6-aaed-88701ad61ff9) | Early terra-medium inline reject |
| [bc578ce3](bc578ce3-28bb-405e-aded-85fb66dfd954) | Orchestrator T01–T70; enum freeze; Gemini rule; Phase 1 validation |

Transcripts: `~/.cursor/projects/home-dio-ubuntu-dio-koding-project-verasic-lab-verasic-skills/agent-transcripts/<uuid>/`

## Regression prompt

> find 5 most popular soccer players, study eating habits, dispatch each to subagent grok high, fuse with subagent gemini flash medium

Pass: `subagent-grok-reasoning-high-fast` (parallel) + `subagent-gemini-3.6-flash-reasoning-medium-notfast` (fuse) via **`subagent_type`**, after roster in `.cursor/agents/` and **new chat**.
