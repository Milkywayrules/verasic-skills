# verasic-init — protocol

Single source of truth for how init wires installed Verasic skills into a repository.

## Design

- `manifest.txt` is the registry: `skill-name|wire-script|description` per line, `#` comments allowed. Wire script paths are relative to the skill's own directory; `-` means skill-only (no repo wiring).
- Init derives the skills root from its own location (`<skills-root>/verasic-init/scripts/init.sh`), so it works under `.cursor/skills/`, `.agents/skills/`, or any other install root without configuration.
- Init never re-implements a skill's setup. Each skill owns its wiring script; init detects, runs, and reports.

## Wire script contract

| Exit code | Meaning | Init status |
| --- | --- | --- |
| 0 | wired (or already wired — idempotent) | `wired` |
| 3 | manual step required; instructions printed to stdout | `action needed` |
| other | error | `FAILED` (init exits 1) |

Scripts must be idempotent, must run correctly from the repo root (init `cd`s there), and must never print secret values.

## Per-skill wiring

| Skill | Script | What it does |
| --- | --- | --- |
| `verasic-github-env` | `scripts/bootstrap.sh` | `.envrc`, `.env.example` GH block, `.gitignore`, credential template |
| `verasic-git-commits` | `scripts/wire-hook.sh` | sets `core.hooksPath` to the skill's hooks dir; prints a lefthook snippet or chaining instructions instead of clobbering existing hook setups (exit 3) |
| `verasic-bugbot` | — | skill-only; nothing to wire |

## Statuses in the report

| Status | Meaning |
| --- | --- |
| `wired` | wiring script succeeded |
| `ready` | installed, no wiring needed |
| `action needed` | manual step required — instructions in details |
| `not installed` | in manifest but not present in the skills root |
| `not selected` | excluded by `--skills` |
| `unknown` | requested via `--skills` but not in the manifest |
| `installed` | `--list` mode only — present, would be wired on a real run |
| `FAILED` | wiring script errored or missing — init exits 1 |

## Report contract

The full stdout of `init.sh` is the user-facing report. Agents relay it verbatim in a code block. It contains: repo root, origin (credentials stripped from the URL), skills root, a status table, per-skill details (wire script output), a result tally, and a `next:` line. Errors before the report (not a git repo, broken install) go to stderr with exit 1 — relay that message instead.

## Adding a new verasic skill

1. Give the skill an idempotent wiring script following the contract above (or use `-`).
2. Add one line to `manifest.txt`.
3. Extend `scripts/test-regression.sh` with at least one assertion for it.

## Failure behavior

- Not a git repo → exit 1 before any changes.
- Unknown CLI argument or empty `--skills` → usage + exit 2.
- Any wire script exit code other than 0/3, or a manifest-declared wire script missing from an installed skill → report row `FAILED`, init exit 1.
- `--list` and `--help` never modify the repository.

## Manifest parsing rules

- One entry per line: `skill-name|wire-script|description`; `#` comments and blank lines skipped.
- Whitespace around `name` and `wire-script` is stripped; a trailing newline on the last line is optional; CRLF tolerated.
- `--skills` values are whitespace-normalized, so `--skills " a, b "` equals `--skills a,b`.
