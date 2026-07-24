# verasic-init — protocol

Single source of truth for how init plans and wires installed Verasic skills into a repository.

## Design

- **Confirm-first:** default run prints a setup plan and changes nothing. Pass `--yes` to apply repo wiring and optional upstream Cursor UX fetch (`cursor` / `cursor-hybrid`). See `references/install-profiles.md`.
- **Effective scope** threads through profile checklist, UX fetch, usage, versions, and skill-root listing. With `--skills a,b`, scope is exactly those skills; without `--skills`, scope is manifest skills physically installed in the repo. The report always includes a **scope** section (effective list + source).
- `manifest.txt` is the registry: `skill-name|wire-script|verify-script|description` per line, `#` comments allowed. Wire script paths are relative to the skill's own directory; `-` means skill-only (no repo wiring). Verify script `-` means no manifest verify step; init runs it only with `--verify`.
- Legacy three-field lines (`skill-name|wire-script|description`) remain valid — the third field is treated as description with no verify script.
- Init discovers **repo-local** skills roots under the git root (`.agents/skills`, `.cursor/skills`, and `skills/` under other hidden agent folders). It **never** wires skills from outside the repository — even when init is invoked from an external install path.
- Each skill ships `integrity.txt` listing required relative paths and `integrity.sha256` with expected hashes for those files (excluding `integrity.sha256` itself).
- Init runs `check_integrity` before wiring and again after wire scripts when applicable. By default, `check_hash_integrity` compares live hashes against `integrity.sha256` and reports `modified:` paths (detect only — no auto-restore). Pass `--no-strict-integrity` for presence-only checks (skip hash comparison).
- Each skill ships a semver `VERSION` file (one line, like `.nvmrc`). The report always includes a **versions** section with local versions; `--check-updates` fetches upstream `VERSION` files read-only.
- Root `versions.lock` in the verasic-skills repo pins expected skill versions for releases. **`scripts/check-versions.sh` enforces lock ↔ VERSION sync in CI** — see upstream [release-protocol.md](https://github.com/Milkywayrules/verasic-skills/blob/main/references/release-protocol.md).
- `VERSION` is listed in each skill's `integrity.txt`; `integrity.sha256` hashes it. Bump `VERSION` → run `scripts/refresh-integrity.sh <skill>` before release.
- Init never re-implements a skill's setup. Each skill owns its wiring script; init detects, plans, runs (with `--yes`), and reports.

## Install profiles

Profiles select the skills root and optional Cursor UX install. Spec: `references/install-profiles.md`.

| Profile | `--yes` installs | Skills root for wiring |
| ------- | ---------------- | ---------------------- |
| `cursor` | `.cursor/{commands,rules,agents}/` fetched from upstream `cursor/` at skill tag `v<VERSION>` (fallback `main`), filtered to effective scope | `.cursor/skills/` |
| `agent` | nothing (skills.sh, Claude Code, Codex, Kiro, …) | `.agents/skills/` |
| `cursor-hybrid` | same scoped Cursor UX fetch as `cursor` | `.agents/skills/` |

Flags: `--profile …`, aliases `--cursor`, `--agent`, `--cursor-hybrid`; default `--profile auto` detects from repo layout.

Fetch failure for `cursor` / `cursor-hybrid` adds a `cursor-ux` **FAILED** row, prints URLs in **profile actions**, tallies in **failed**, and init exits **1** (repo wiring may still have run).

## Skills root selection

1. Discover all repo-local skills directories.
2. Require a repo-local `verasic-init/scripts/init.sh`. If none exists, exit 1 — do not fall back to the external invoker's skills tree.
3. Select the wiring root (after profile resolution):
   - prefer the root that contains the **invoked** `verasic-init` when that root is repo-local;
   - otherwise tie-break per profile (see `references/install-profiles.md`).
4. When the invoked init path is outside `REPO_ROOT`, print a **warning** in the report and still use repo-local skills only.

## Integrity checker

`check_integrity(skill_dir)` reads `integrity.txt` (`#` comments and blank lines ignored). Reports:

- `missing:<path>` — required file absent
- `empty:<path>` — required file present but zero bytes

`check_hash_integrity(skill_dir)` reads `integrity.sha256` (sha256sum format: `hash  path`). Reports:

- `modified:<path>` — file missing or hash mismatch

Used in `--list` mode and before/after wiring. Hash checks run by default; hash mismatch before wire → `broken install`; after successful wire → `degraded`. With `--no-strict-integrity` (alias `--loose-integrity`), hash checks are skipped and actions note `presence-only`.

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

## Manifest verify (`--verify`)

After a successful wire (exit 0), init may run the manifest verify script for that skill when `--verify` is passed. Verify scripts are listed in the fourth manifest column; `-` skips.

- `verasic-github-env`: `scripts/check-gh.sh` — init orchestrates this on `--verify` even when bootstrap already verified on token presence.
- Other skills: `-` today.

If any manifest verify script fails, init reports `verify: failed` in actions, tallies verify failures, and exits 3 (after the full report). Broken installs and wire failures still exit 1 first.

## Per-skill wiring

| Skill                 | Wire                   | Verify                 | What it does                                                                                                                                           |
| --------------------- | ---------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `verasic-github-env`  | `scripts/bootstrap.sh` | `scripts/check-gh.sh`  | `.envrc`, `.env.example` GH block, `.gitignore`, credential template; optional bootstrap verify on token; manifest verify with `--verify`            |
| `verasic-git-commits` | `scripts/wire-hook.sh` | —                      | sets `core.hooksPath` to the skill's hooks dir; prints a lefthook snippet or chaining instructions instead of clobbering existing hook setups (exit 3) |
| `verasic-bugbot`      | —                      | —                      | skill-only; nothing to wire                                                                                                                            |
| `verasic-fusion`      | —                      | —                      | skill-only; multi-model fusion orchestration                                                                                                           |
| `verasic-deep-research` | —                      | —                      | skill-only; ledger-backed research                                                                                                                     |
| `verasic-init`        | —                      | —                      | this orchestrator; running it is the wiring                                                                                                            |

## Statuses in the report

| Status          | Meaning                                                                 |
| --------------- | ----------------------------------------------------------------------- |
| `verified`      | wired + `check-gh.sh` passed (`verasic-github-env` only in slice A)     |
| `wired`         | wiring script succeeded; integrity ok; verify skipped (no token)        |
| `degraded`      | wire ran but integrity incomplete, hash mismatch (default hash checks), or verify skipped (check-gh missing) |
| `ready`         | installed skill-only skill; integrity ok                                |
| `ok`            | `--list` only — would wire; integrity ok                                |
| `broken install`| required integrity files missing or hash mismatch before wire           |
| `action needed` | manual step required — instructions in details, or manifest verify failed |
| `not installed` | in manifest but not present in any repo-local root                      |
| `not selected`  | excluded by `--skills`                                                  |
| `unknown`       | requested via `--skills` but not in the manifest                        |
| `FAILED`        | wiring script errored, or `cursor-ux` upstream fetch failed — init exits 1 |

## Report contract

The full stdout of `init.sh` is the user-facing report. Agents relay it verbatim in a code block. It contains:

- repo root, origin (credentials stripped), selected skills root
- external-invoker warning when applicable
- **scope** — effective skill list and source (`--skills` or installed subset)
- **install profile**, **profile checklist**, **usage** (omitted in `--list` only)
- **skill roots** — each discovered root with per-skill integrity summary (scoped when `--skills`)
- **versions** — local `VERSION` per skill in effective scope; with `--check-updates`, upstream comparison
- status table, per-skill **details** (wire script output), **actions** (integrity + steps + verify)
- result tally and a `next:` line

Errors before the report (not a git repo, no repo-local verasic-init, broken manifest) go to stderr with exit 1.

## Adding a new verasic skill

1. Add `integrity.txt` listing required paths and generate `integrity.sha256`.
2. Add a one-line semver `VERSION` file.
3. Give the skill an idempotent wiring script following the contract above (or use `-` for wire and verify columns).
4. Add one line to `manifest.txt` (four-field preferred).
5. Bump `versions.lock` when releasing; run `bash scripts/check-versions.sh` (see upstream [release-protocol.md](https://github.com/Milkywayrules/verasic-skills/blob/main/references/release-protocol.md)).
6. Extend `scripts/test-regression.sh` with at least one assertion for it.

## Failure behavior

- Not a git repo → exit 1 before any changes.
- No repo-local `verasic-init` → exit 1 (external invoker does not substitute).
- Unknown CLI argument or empty `--skills` → usage + exit 2.
- `--skills` selection where every name is unknown → report + exit 2.
- Any `FAILED` or `broken install` row → init exit 1.
- Manifest verify failure with `--verify` → exit 3.
- `action needed`, `degraded`, `wired`, `verified`, and `--list` with only non-fatal rows → exit 0.
- `--list`, `--check-updates`, and `--help` never modify the repository.
- Default (no `--yes`, no `--list`) is plan-only — same read-only guarantee as `--list` for mutations, but includes profile guidance.

## Manifest parsing rules

- Preferred: `skill-name|wire-script|verify-script|description`
- Legacy: `skill-name|wire-script|description` (no verify script)
- `#` comments and blank lines skipped.
- Whitespace around `name`, `wire-script`, and `verify-script` is stripped; a trailing newline on the last line is optional; CRLF tolerated.
- `--skills` values are whitespace-normalized, so `--skills " a, b "` equals `--skills a,b`.

## Version check (`--check-updates`)

Read-only. Fetches `https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/skills/<skill>/VERSION` (override with `VERASIC_INIT_REMOTE_VERSION_BASE` for tests). Compares to local `VERSION`. Never auto-overwrites installed skills.
