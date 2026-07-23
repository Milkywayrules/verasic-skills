Plan and apply Verasic setup for this repository (confirm-first).

**Step 1 — plan (no changes):** run from the repository root:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh   # append flags I gave, e.g. --profile agent or --list
```

If I already said `--yes` or `--confirm`, skip to step 2 with the same flags.

**Step 2 — after I confirm:** run again with `--yes` and the agreed profile:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor   # or agent / cursor-hybrid / auto
```

Then:

1. Relay each report **verbatim** in a code block — full stdout from the first `────` rule to the last. Do not summarize, soften, or reformat. If init fails before printing a report, relay stderr instead.
2. On the plan pass, explain the detected profile, checklist gaps, and usage section; ask which profile to apply before running `--yes`.
3. If any row says `action needed`, walk me through the manual steps from details, wait for me to finish, then re-run `--yes` to confirm.
4. If `verasic-github-env` was wired, remind me: create a fine-grained PAT, put it in `.github-agent.local` (chmod 600), verify with `check-gh.sh`.

Profiles: `cursor` (full Cursor), `agent` (skills.sh / Claude Code / Codex / Kiro / …), `cursor-hybrid` (skills in `.agents/skills/` + Cursor slash UX). Spec: `.cursor/skills/verasic-init/references/install-profiles.md`

Never run `gh auth login`; never edit lefthook/husky configs yourself — the report prints snippets for me instead.
