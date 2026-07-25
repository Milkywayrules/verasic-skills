---
name: verasic-init
description: Confirm-first repo setup for installed Verasic skills — detects install profile (cursor, agent, cursor-hybrid), prints checklist and usage, then with --yes wires github-cli-init bootstrap and git-commits hook and optionally fetches Cursor UX from upstream raw GitHub. Use when the user asks to "init verasic", "set up verasic skills", "bootstrap this repo for verasic", or right after installing via setup.sh or skills.sh.
disable-model-invocation: true
---

Security: see `references/scanner-notes.md` and upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md) for expected scanner signals and trust model.

# Verasic Init — Repo Setup Orchestrator

Source of truth: `references/init-protocol.md` (wire contract, statuses, extension guide). Profiles: `references/install-profiles.md`.

## Orchestration (Cursor)

Plan and apply Verasic setup for this repository (confirm-first).

**Step 1 — plan (no changes):** run from the repository root:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh   # append flags the user gave, e.g. --profile agent or --list
```

If the user already said `--yes` or `--confirm`, skip to step 2 with the same flags.

**Step 2 — after confirmation:** run again with `--yes` and the agreed profile:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor   # or agent / cursor-hybrid / auto
```

Then:

1. Relay each report **verbatim** in a code block — full stdout from the first `────` rule to the last. Do not summarize, soften, or reformat. If init fails before printing a report, relay stderr instead.
2. On the plan pass, explain the detected profile, checklist gaps, and usage section; ask which profile to apply before running `--yes`.
3. If any row says `action needed`, walk the user through the manual steps from details, wait for them to finish, then re-run `--yes` to confirm.
4. If `verasic-github-cli-init` was wired, remind them: create a fine-grained PAT, put it in `.github-agent.local` (chmod 600), verify with `check-gh.sh`.

Profiles: `cursor` (full Cursor), `agent` (skills.sh / Claude Code / Codex / Kiro / …), `cursor-hybrid` (skills in `.agents/skills/` + Cursor slash UX). Spec: `.cursor/skills/verasic-init/references/install-profiles.md`

Never run `gh auth login`; never edit lefthook/husky configs yourself — the report prints snippets for the user instead.

## Workflow

1. **Plan first (default)** — from the repo root, run without `--yes`:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh
bash .cursor/skills/verasic-init/scripts/init.sh --profile agent   # optional profile hint
```

Installed under a different root (e.g. `.agents/skills/`)? Adjust the path prefix. Append flags the user gave (`--list`, `--check-updates`, …).

2. **Relay the plan verbatim** — print init's full stdout in a code block, unmodified. Explain the detected profile, scope, checklist gaps, and usage section; **ask the user which profile to apply** (`cursor`, `agent`, `cursor-hybrid`) before mutating anything.

3. **Apply after confirmation** — only when the user agrees:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor
```

Relay that report verbatim too.

4. If any row says `action needed`, walk the user through manual steps in details, wait, then re-run with `--yes`.
5. If `verasic-github-cli-init` was wired, remind: create PAT, set `GH_TOKEN` in `.github-agent.local`, verify with `check-gh.sh`.

## Profiles

| Profile | Who |
| ------- | --- |
| `cursor` | Full Cursor (`setup.sh` or skills under `.cursor/skills/`) |
| `agent` | skills.sh, Claude Code, Codex, Kiro, Windsurf, … |
| `cursor-hybrid` | `npx skills add` (`.agents/skills/`) + Cursor slash UX |

Aliases: `--cursor`, `--agent`, `--cursor-hybrid`. Default auto-detects from repo layout.

**Upstream Cursor UX (v0.2.4+):** on `--yes`, `cursor` / `cursor-hybrid` fetch from upstream **`main/cursor/`** unless the user set `VERASIC_INIT_BUNDLE_TAG` or `VERASIC_INIT_REMOTE_REPO_BASE`. Plan report **ux upstream** is the fetch base; **latest bundle** is informational only (not the fetch default). Do not treat a missing or old bundle tag as a fetch failure by itself.

## Inspect and cherry-pick

```bash
bash .cursor/skills/verasic-init/scripts/init.sh --list
bash .cursor/skills/verasic-init/scripts/init.sh --yes --skills verasic-github-cli-init,verasic-bugbot
bash .cursor/skills/verasic-init/scripts/init.sh --yes --verify --profile cursor
bash .cursor/skills/verasic-init/scripts/init.sh --check-updates
```

## Hard rules

- **Never run `--yes` without user confirmation** — default plan is the safe path.
- Relay reports verbatim; they are the user-facing deliverable.
- Never run `gh auth login` or edit lefthook/husky config — wire scripts print snippets instead.
- Init must run inside a git repository; `--list` and plan mode change nothing.
- Repo-local skills only — external invoker paths get a warning, not silent cross-repo wiring.
