# verasic-init — protocol

Single source of truth for how init wires installed Verasic skills into a repository.

## Design

- `manifest.txt` is the registry: `skill-name|wire-script|description` per line, `#` comments allowed. Wire script paths are relative to the skill's own directory; `-` means skill-only (no repo wiring).
- Init discovers **repo-local** skills roots under the git root (`.agents/skills`, `.cursor/skills`, and `skills/` under other hidden agent folders). It **never** wires skills from outside the repository — even when init is invoked from an external install path.
- Each skill ships `integrity.txt` listing required relative paths. Init runs `check_integrity` before wiring and again after wire scripts when applicable.
- Init never re-implements a skill's setup. Each skill owns its wiring script; init detects, runs, and reports.

## Skills root selection

1. Discover all repo-local skills directories.
2. Require a repo-local `verasic-init/scripts/init.sh`. If none exists, exit 1 — do not fall back to the external invoker's skills tree.
3. Select the wiring root:
   - prefer the root that contains the **invoked** `verasic-init` when that root is repo-local;
   - otherwise tie-break `.agents/skills`, then `.cursor/skills`, then first discovered root.
4. When the invoked init path is outside `REPO_ROOT`, print a **warning** in the report and still use repo-local skills only.

## Integrity checker

`check_integrity(skill_dir)` reads `integrity.txt` (`#` comments and blank lines ignored). Reports:

- `missing:<path>` — required file absent
- `empty:<path>` — required file present but zero bytes

Used in `--list` mode and before/after wiring.

## Wire script contract

| Exit code | Meaning                                              | Init status (typical)   |
| --------- | ---------------------------------------------------- | ----------------------- |
| 0         | wired (or already wired — idempotent)                | `wired` / `verified` / `degraded` |
| 3         | manual step required; instructions printed to stdout | `action needed`         |
| other     | error                                                | `FAILED` (init exits 1) |

Scripts must be idempotent, must run correctly from the repo root (init `cd`s there), and must never print secret values.

`verasic-github-env` bootstrap may print machine-readable verify lines:

- `bootstrap: verify: ok` → init status `verified`
- `bootstrap: verify: skipped (no token)` → `wired`
- `bootstrap: verify: skipped (check-gh missing)` → `degraded`
- `bootstrap: verify: failed` → bootstrap exits 3 → `action needed`

Bootstrap step lines (`bootstrap: step: ran|skipped|cannot …`) feed the report **actions** section.

## Per-skill wiring

| Skill                 | Script                 | What it does                                                                                                                                           |
| --------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `verasic-github-env`  | `scripts/bootstrap.sh` | `.envrc`, `.env.example` GH block, `.gitignore`, credential template; optional `check-gh` verify; exit 3 when secrets tracked or verify fails          |
| `verasic-git-commits` | `scripts/wire-hook.sh` | sets `core.hooksPath` to the skill's hooks dir; prints a lefthook snippet or chaining instructions instead of clobbering existing hook setups (exit 3) |
| `verasic-bugbot`      | —                      | skill-only; nothing to wire                                                                                                                            |
| `verasic-fusion`      | —                      | skill-only; multi-model fusion orchestration                                                                                                           |
| `verasic-init`        | —                      | this orchestrator; running it is the wiring                                                                                                            |

## Statuses in the report

| Status          | Meaning                                                                 |
| --------------- | ----------------------------------------------------------------------- |
| `verified`      | wired + `check-gh.sh` passed (`verasic-github-env` only in slice A)     |
| `wired`         | wiring script succeeded; integrity ok; verify skipped (no token)        |
| `degraded`      | wire ran but integrity incomplete, or verify skipped (check-gh missing) |
| `ready`         | installed skill-only skill; integrity ok                                |
| `ok`            | `--list` only — would wire; integrity ok                                |
| `broken install`| required integrity files missing before wire                            |
| `action needed` | manual step required — instructions in details                          |
| `not installed` | in manifest but not present in any repo-local root                      |
| `not selected`  | excluded by `--skills`                                                  |
| `unknown`       | requested via `--skills` but not in the manifest                        |
| `FAILED`        | wiring script errored — init exits 1                                    |

## Report contract

The full stdout of `init.sh` is the user-facing report. Agents relay it verbatim in a code block. It contains:

- repo root, origin (credentials stripped), selected skills root
- external-invoker warning when applicable
- **skill roots** — each discovered root with per-skill integrity summary
- status table, per-skill **details** (wire script output), **actions** (integrity + steps)
- result tally and a `next:` line

Errors before the report (not a git repo, no repo-local verasic-init, broken manifest) go to stderr with exit 1.

## Adding a new verasic skill

1. Add `integrity.txt` listing required paths.
2. Give the skill an idempotent wiring script following the contract above (or use `-`).
3. Add one line to `manifest.txt`.
4. Extend `scripts/test-regression.sh` with at least one assertion for it.

## Failure behavior

- Not a git repo → exit 1 before any changes.
- No repo-local `verasic-init` → exit 1 (external invoker does not substitute).
- Unknown CLI argument or empty `--skills` → usage + exit 2.
- `--skills` selection where every name is unknown → report + exit 2.
- Any `FAILED` or `broken install` row → init exit 1.
- `action needed`, `degraded`, `wired`, `verified`, and `--list` with only non-fatal rows → exit 0.
- `--list` and `--help` never modify the repository.

## Manifest parsing rules

- One entry per line: `skill-name|wire-script|description`; `#` comments and blank lines skipped.
- Whitespace around `name` and `wire-script` is stripped; a trailing newline on the last line is optional; CRLF tolerated.
- `--skills` values are whitespace-normalized, so `--skills " a, b "` equals `--skills a,b`.
