Initialize this repository for the Verasic skills that are installed.

Run from the repository root:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh   # append any flags I gave, e.g. --skills a,b or --list
```

Then:

1. Relay the report **verbatim** in a code block — full stdout from the first `────` rule to the last, do not summarize, soften, or reformat it. If init fails before printing a report, relay its stderr message instead.
2. If any row says `action needed`, walk me through the manual steps from the details section, wait for me to finish them, then re-run init to confirm.
3. If `verasic-github-env` was wired, remind me of the human steps: create a fine-grained PAT, put it in `.github-agent.local` (chmod 600), verify with `check-gh.sh`.

Init is idempotent and read-only with `--list`. Never run `gh auth login`; never edit lefthook/husky configs yourself — the report prints snippets for me instead.
