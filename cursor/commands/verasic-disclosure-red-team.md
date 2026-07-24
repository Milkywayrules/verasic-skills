Run the verasic agent disclosure red-team regression from the repository root.

From the repo root, run:

```bash
bash .cursor/skills/verasic-agent-disclosure/scripts/run-red-team.sh
```

When skills live under `.agents/skills/`, adjust the path prefix accordingly.

After the script finishes, relay its summary output verbatim — do not soften FAIL rows or omit ERROR rows. If everything passed, say so plainly.

Do not run ad-hoc extraction prompts instead of the script unless the script is unavailable; if unavailable, say so and stop.
