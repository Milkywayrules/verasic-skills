Run a Bugbot-like review of my local changes.

Launch the `verasic-bug-reviewer` subagent with this prompt:

"Full Repository Path: <current workspace root>
Diff: branch changes (use 'uncommitted changes' if I said so in my message)
Follow your system prompt fully: read full files, trace callers, apply the checklists in .cursor/skills/verasic-bugbot/checklists/ (or .agents/skills/verasic-bugbot/checklists/ for cursor-hybrid installs), filter aggressively, and report in your standard output format."

After the subagent returns, relay its findings verbatim — do not soften severities or drop issues. If it found zero issues, say so plainly.

Bugbot-only — use `/verasic-security-review` for STRIDE security depth.

After the summary, if the diff touches auth, crypto, webhooks, or user-input validation, add ONE line: `Tip: auth/crypto/webhook/input changes — run /verasic-security-review for STRIDE depth.`
