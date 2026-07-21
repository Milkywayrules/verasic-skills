# Security

**This file is the project security policy** for [Milkywayrules/verasic-skills](https://github.com/Milkywayrules/verasic-skills). Enable it as the GitHub Security Policy in repo settings if the Security tab is not yet wired.

verasic-skills is an **agent harness** — markdown protocols, Cursor rules/commands, and
small bash wiring scripts that help AI-assisted development workflows. It is **not** a
runtime application, server, or npm package that executes in production.

Published on [skills.sh](https://skills.sh/milkywayrules/verasic-skills).

## Why static scanners flag these skills

`npx skills add Milkywayrules/verasic-skills` runs third-party security scanners
(Gen, Socket, Snyk, and similar). Harness skills routinely trigger alerts because they
**intentionally** touch sensitive developer surfaces:

| Pattern scanners see | Why it exists here |
| -------------------- | ------------------ |
| Secrets / credentials | `verasic-github-env` documents `.github-agent.local` and `GH_TOKEN` |
| Git hook wiring | `verasic-git-commits` installs a `commit-msg` hook via `core.hooksPath` |
| `git config` | Wire scripts set repo-local hook paths idempotently |
| Network (`curl`) | `verasic-init --check-updates` fetches upstream `VERSION` files read-only |
| Shell execution | Bootstrap, verify, and regression scripts are bash |

These are **expected false positives** for a local-dev harness — not indicators of
malware. Review the skill source (`SKILL.md`, `references/`, `scripts/`) before trusting
any install path.

## Expected scan signals (typical at install time)

Counts and severities may drift as vendors retune heuristics. This table reflects what
installers commonly see on [skills.sh](https://skills.sh/milkywayrules/verasic-skills)
as of mid-2026 — **expected harness noise**, not proof of a vulnerability.

| Skill | Gen (typical) | Socket (typical) | Snyk (typical) | Expected? |
| ----- | ------------- | ---------------- | -------------- | --------- |
| **verasic-github-env** | High | — | Critical (bundle) | Yes — credential docs + env loader |
| **verasic-git-commits** | High | — | Critical (bundle) | Yes — hook + `core.hooksPath` |
| **verasic-init** | — | 1 alert | Critical (bundle) | Yes — orchestrates hook/bootstrap + `curl` |
| **verasic-fusion** | — | — | Critical (bundle) | Yes — bundle inheritance |
| **verasic-bugbot** | — | — | Critical (bundle) | Yes — bundle + security checklist keywords |

Per-skill detail: `skills/<name>/references/scanner-notes.md` (linked in [Related](#related)).

## FAQ

### Why is Snyk still Critical?

Snyk scores the **whole skill bundle** at install time. Harness skills intentionally
document credentials, install git hooks, run bash wiring scripts, and (for init) may
`curl` upstream version files. Static analysis treats those patterns as high risk even
when the behavior is read-only, repo-local, and documented. **Critical here means
"matches sensitive-dev-tool heuristics" — not "malware" or "CVE in production."** More
prose will not turn marketplace badges green; verify trust via source review and
`integrity.sha256` instead.

## Trust model

1. **Read before run** — Each skill ships `SKILL.md` plus a `references/` protocol.
   Agents follow those files; scripts only do what the protocol describes.
2. **Hash integrity (default on)** — `verasic-init` compares installed files against
   per-skill `integrity.sha256` before wiring. Mismatch → `broken install` or
   `degraded`; **detect-only, never auto-restore**.
3. **Repo-local only** — Init wires skills from inside your git repo (`.cursor/skills/`,
   `.agents/skills/`, etc.). It never pulls wiring from an external checkout path.
4. **Idempotent wiring** — Re-running init or bootstrap is safe; wire scripts do not
   clobber unrelated hook managers without printing manual instructions (exit 3).
5. **No silent history rewrite** — Commit audit and trailer fix modes require explicit
   user approval.

Opt out of hash checks only when you intentionally fork a skill locally:
`init.sh --no-strict-integrity`.

## Credential handling

| Rule | Detail |
| ---- | ------ |
| Local agents | `GH_TOKEN` in gitignored `.github-agent.local` (`chmod 600`) |
| PAT scope | One fine-grained PAT **per repo**, scoped to that repo only |
| Never commit | Tokens, `.github-agent.local`, `.env.local` with secrets |
| CI / production | GitHub Actions secrets or a vault — never mix with agent tier |
| Loader safety | `load-gh-env.sh` parses `GH_*` lines; it does **not** `source` arbitrary shell |
| Verify | `check-gh.sh` confirms token presence and `gh auth status` without logging values |

See `skills/verasic-github-env/references/setup-protocol.md` for the full tier table.

## What each skill can do

| Skill | Repo mutations | Network | Notes |
| ----- | -------------- | ------- | ----- |
| **verasic-init** | Runs other skills' wire scripts; no direct file edits of its own | Optional: `--check-updates` curls upstream `VERSION` | Orchestrator only |
| **verasic-github-env** | `.envrc`, `.env.example` GH block, `.gitignore`, credential template | Via `gh` after you set `GH_TOKEN` | Does not create PATs or run `gh auth login` loops |
| **verasic-git-commits** | Sets `git config core.hooksPath` to skill hooks (or prints lefthook snippet) | None | Hook strips attribution trailers pre-commit; audit is read-only |
| **verasic-fusion** | None (decision support) | Subagent/model APIs only when you invoke fusion | No edits, commits, or deploys |
| **verasic-bugbot** | None (review only) | None | Reads git diffs and full files; reports bugs |

## Install paths

- **Cursor full setup:** `curl …/setup.sh | bash` — clones this repo shallowly and copies
  rules, commands, agents, and skills into `.cursor/`. Same trust model as
  `npx skills add`: read `SKILL.md` and scripts first; prefer a pinned tag URL over
  `main` when piping remote shell; verify `integrity.sha256` after install.
- **Skills only:** `npx skills add Milkywayrules/verasic-skills`.
- **Post-install wiring:** `/verasic-init` or `bash …/verasic-init/scripts/init.sh`.

Prefer pinning to a tagged release or verifying `integrity.sha256` after install.

## Reporting issues

Open a GitHub issue on [Milkywayrules/verasic-skills](https://github.com/Milkywayrules/verasic-skills)
for:

- Suspected malicious or unexpected behavior in scripts
- Integrity hash mismatches after a clean install
- Credential handling bugs or accidental secret logging
- Scanner findings you believe indicate a real vulnerability (not harness false positives)

Include skill name, install path, command run, and redacted logs (never paste tokens).

## Related

- [skills.sh listing](https://skills.sh/milkywayrules/verasic-skills) — install audits and community signals
- Root [README.md](README.md) — install and usage overview
- Per-skill scanner notes:
  - [skills/verasic-init/references/scanner-notes.md](skills/verasic-init/references/scanner-notes.md)
  - [skills/verasic-github-env/references/scanner-notes.md](skills/verasic-github-env/references/scanner-notes.md)
  - [skills/verasic-git-commits/references/scanner-notes.md](skills/verasic-git-commits/references/scanner-notes.md)
  - [skills/verasic-fusion/references/scanner-notes.md](skills/verasic-fusion/references/scanner-notes.md)
  - [skills/verasic-bugbot/references/scanner-notes.md](skills/verasic-bugbot/references/scanner-notes.md)
