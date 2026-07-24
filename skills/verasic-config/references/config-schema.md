# Verasic config — trackedDir vs localDir

Single source of truth for artifact path semantics. Types live in
`schema/verasic.config.ts`; this doc explains the pairing.

## Overview

Verasic skills write durable and ephemeral artifacts under two configurable roots:

| Key | Default | Git | Typical use |
| --- | --- | --- | --- |
| `artifacts.trackedDir` | `verasic` | commit when you want | promoted reports, team defaults, policies |
| `artifacts.localDir` | `.verasic` | **gitignored** | last run, reruns, local experiments |

**Why two dirs:** `trackedDir` holds artifacts you may share and want indexed;
`localDir` holds machine-local output that should never land in git history.

## trackedDir

- Repo-relative path for **durable, commit-friendly** artifacts.
- Default subdirs created by scaffold: `verasic/.gitkeep`,
  `verasic/security-reviews/.gitkeep`.
- Security review with `report.promote: 'both' | 'tracked'` writes promoted
  copies here.
- Indexed by Cursor/@codebase like normal repo files when committed.

## localDir

- Repo-relative path for **gitignored machine-local** artifact root.
- Pairs with `trackedDir`: same logical subdirs (e.g. `security-reviews/`) may
  exist under both; local holds the full run, tracked holds the promoted slice.
- Init scaffold appends `localDir/` to `.gitignore` (idempotent).
- Not in git history by design — rotate or delete freely.

## indexLocal

- Default `false` — `localDir` is gitignored and scaffold appends it to
  `.cursorignore` so local runs stay out of the semantic index.
- When `true`, only `localDir` is gitignored; agents can still read explicit
  paths under `localDir` when mentioned in chat. Override during wire with
  `VERASIC_INDEX_LOCAL=false` to force `.cursorignore` even when `indexLocal` is
  `true`.

## securityReview.report

| Key | Default | Meaning |
| --- | --- | --- |
| `write` | `true` | emit report files when the skill runs |
| `promote` | `both` | `both` → local + tracked; `local` or `tracked` for one side only |

Reports land under `{localDir}/security-reviews/` and/or
`{trackedDir}/security-reviews/` per `promote`.

## Config files (repo root)

| File | Format |
| --- | --- |
| `verasic.config.ts` | TypeScript — primary; comments + typed schema |
| `.verasicrc.json` | Strict JSON — one root object; **not JSONL** |
| `.verasicrc.jsonc` | Optional JSON with comments — human-friendly alias |

Shell skills call `scripts/resolve-config.sh` — resolution order:
`verasic.config.ts` → `.verasicrc.jsonc` → `.verasicrc.json` → defaults (first present file wins, merged over defaults).

## securityReview.scanner

| Value | Behavior |
| --- | --- |
| `off` | LLM-only review (default) |
| `semgrep` | Semgrep on changed paths |
| `opengrep` | OpenGrep on changed paths |
| `auto` | try OpenGrep, then Semgrep |

Scanner findings are **Deterministic**; LLM findings are **Heuristic**.

## securityReview.strictness

| Value | Behavior |
| --- | --- |
| `strict` | higher bar, fewer findings (default) |
| `assertive` | broader surface, more findings |

## Example layout after scaffold

```text
verasic.config.ts          # user-owned hub (optional if .verasicrc.json exists)
.verasicrc.json            # optional JSON alias
verasic/                   # trackedDir — commit selectively
  security-reviews/
.verasic/                  # localDir — gitignored
  security-reviews/
```

Skills remain under `.agents/skills/` or `.cursor/skills/` — never inside
`.verasic/`.
