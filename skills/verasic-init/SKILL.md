---
name: verasic-init
description: One-command repo initialization for installed Verasic skills — discovers repo-local verasic-* skills, checks integrity.txt manifests, runs each skill's wiring script idempotently (github-env bootstrap, git-commits hook), and prints a setup report to relay verbatim. Use when the user asks to "init verasic", "set up verasic skills", "bootstrap this repo for verasic", or right after installing verasic-skills via setup.sh or skills.sh.
---

Security: see `references/scanner-notes.md` and repo root `SECURITY.md` for expected scanner signals and trust model.

# Verasic Init — Repo Wiring Orchestrator

Source of truth: `references/init-protocol.md` (wire contract, statuses, multi-root discovery, extension guide).

## Workflow

1. From the repo root, run the script at `scripts/init.sh` inside this skill's directory. In Cursor installs that is:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh
```

Installed under a different root (e.g. `.agents/skills/`)? Adjust the path prefix — the script itself needs no configuration. Append any flags the user gave (`--skills a,b`, `--list`, `--verify`, `--no-strict-integrity`, `--check-updates`).

2. **Relay the report verbatim** — print init's full stdout to the user in a code block, unmodified, from the first `────` rule to the last. Do not summarize, soften, or reformat it. If init exits before printing a report (not a git repo, no repo-local install, broken manifest), relay its stderr message instead.
3. If any row says `action needed`, walk the user through the manual steps shown in the details section, wait for them to finish, then re-run init to confirm.
4. If `verasic-github-env` shows `wired`, `verified`, or `action needed`, remind the user of its human steps (create PAT, set `GH_TOKEN` in `.github-agent.local`, verify with `check-gh.sh`).

## Cherry-pick and inspect

```bash
bash .cursor/skills/verasic-init/scripts/init.sh --skills verasic-github-env,verasic-bugbot   # wire only these
bash .cursor/skills/verasic-init/scripts/init.sh --list                                       # integrity + install state, change nothing
bash .cursor/skills/verasic-init/scripts/init.sh --verify                                     # run manifest verify scripts after wire
bash .cursor/skills/verasic-init/scripts/init.sh --no-strict-integrity                        # presence-only integrity (skip hash checks)
bash .cursor/skills/verasic-init/scripts/init.sh --check-updates                              # compare local VERSION to upstream (read-only)
```

## How it works

`manifest.txt` maps each verasic skill to its own wiring and optional verify script. Init discovers repo-local skills roots, checks each skill's `integrity.txt` and `integrity.sha256` hashes by default (pass `--no-strict-integrity` for presence-only), runs only installed skills' wire scripts, and never uses skills from outside the repository (even when invoked from another checkout). Exit code 3 from a wire script means "manual step required" (reported, not a failure). Exit code 3 from init means manifest verify failed with `--verify`.

## Hard rules

- Init is idempotent — safe to re-run anytime; never warn the user against re-running.
- Relay the report verbatim; the report is the user-facing deliverable.
- Never run `gh auth login` or edit the user's lefthook/husky config — wire scripts print snippets instead.
- Init must run inside a git repository; it changes nothing with `--list` or `--help`.
- Repo-local skills only — external invoker paths get a warning, not silent cross-repo wiring.
