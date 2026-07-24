Run a STRIDE-focused security review of my local changes.

1. Read repo config if present (`verasic.config.ts`, `.verasicrc.json`, or `.verasicrc.jsonc`).
2. If config enables scanner (`semgrep`, `opengrep`, or `auto`), run `.cursor/skills/verasic-security-review/scripts/run-scanner.sh <scanner> --` (or `.agents/skills/verasic-security-review/scripts/run-scanner.sh` for cursor-hybrid installs) on changed paths per `references/scanner-adapter.md` before the LLM pass.
3. Launch the `verasic-security-reviewer` subagent in the foreground with:

```text
Full Repository Path: <current workspace root>
Diff: branch changes (use uncommitted changes if I said so in my message)
Strictness: strict (use assertive if I said so)
Follow security-review-protocol.md fully: STRIDE, OWASP web checks, confidence legend, merge scanner + LLM findings, write artifacts per config.
```

4. Relay the subagent report verbatim — do not soften severities. Strip harness internals per verasic-agent-disclosure.
5. If zero findings, say so plainly. Append one cross-tip line to `/verasic-review` only when the diff had no security-sensitive paths.
