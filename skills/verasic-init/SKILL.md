---
name: verasic-init
description: One-command repo initialization for installed Verasic skills — detects which verasic-* skills are present, runs each skill's wiring script idempotently (github-env bootstrap, git-commits hook), and prints a setup report to relay verbatim. Use when the user asks to "init verasic", "set up verasic skills", "bootstrap this repo for verasic", or right after installing verasic-skills via setup.sh or skills.sh.
---

# Verasic Init — Repo Wiring Orchestrator

Source of truth: `references/init-protocol.md` (wire contract, statuses, extension guide).

## Workflow

1. From the repo root, run the script at `scripts/init.sh` inside this skill's directory. In Cursor installs that is:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh
```

Installed under a different root (e.g. `.agents/skills/`)? Adjust the path prefix — the script itself needs no configuration. Append any flags the user gave (`--skills a,b`, `--list`).

2. **Relay the report verbatim** — print init's full stdout to the user in a code block, unmodified, from the first `────` rule to the last. Do not summarize, soften, or reformat it. If init exits before printing a report (not a git repo, broken install), relay its stderr message instead.
3. If any row says `action needed`, walk the user through the manual steps shown in the details section, wait for them to finish, then re-run init to confirm.
4. If `verasic-github-env` shows `wired` or `action needed`, remind the user of its human steps (create PAT, `.github-agent.local`, verify with `check-gh.sh`).

## Cherry-pick and inspect

```bash
bash .cursor/skills/verasic-init/scripts/init.sh --skills verasic-github-env,verasic-bugbot   # wire only these
bash .cursor/skills/verasic-init/scripts/init.sh --list                                       # show install state, change nothing
```

## How it works

`manifest.txt` in this skill maps each verasic skill to its own wiring script. Init runs only the scripts of skills that are actually installed next to it — it never duplicates their logic. Exit code 3 from a wire script means "manual step required" (reported, not a failure).

## Hard rules

- Init is idempotent — safe to re-run anytime; never warn the user against re-running.
- Relay the report verbatim; the report is the user-facing deliverable.
- Never run `gh auth login` or edit the user's lefthook/husky config — wire scripts print snippets instead.
- Init must run inside a git repository; it changes nothing with `--list` or `--help`.
