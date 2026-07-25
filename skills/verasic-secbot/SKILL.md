---
name: verasic-secbot
description: STRIDE security review on git diff with optional deterministic scanner. Use when the user asks to "security review", "review for security", "STRIDE review", "check my diff for vulnerabilities", or before commit/PR when auth, crypto, webhooks, or untrusted input changed.
disable-model-invocation: true
---

Security: see `references/scanner-notes.md` and upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md) for expected scanner signals and trust model.

# Verasic Secbot — Orchestration

## Workflow

1. Determine scope from the user's message: branch changes (default) or overrides (`uncommitted only`, `staged only`, `against <branch>`). Invoke phrase beats defaults when both set.
2. Resolve run settings from invoke-phrase overrides first, then inlined defaults in `references/config-schema.md`:

| Setting | Default |
| --- | --- |
| `scanner` | `off` |
| `strictness` | `strict` |
| `report.write` | `true` |
| `report.promote` | `both` |
| `trackedDir` | `verasic` |
| `localDir` | `.verasic` |

Invoke-phrase overrides: scope flags, `strict` / `assertive`, `no file`, `save tracked`, scanner override (`off` / `opengrep` / `semgrep` / `auto`).
3. Optional scanner: when `scanner` is not `off`, run `scripts/run-scanner.sh <scanner> --` on changed source paths only (see `references/scanner-adapter.md`). Scanner missing → one-line skip, continue.
4. In Cursor: launch the `verasic-secbot-reviewer` subagent (`.cursor/agents/verasic-secbot-reviewer.md`) with repository path, scope, scanner results (if any), and resolved settings — in the **foreground**. Relay its report unchanged **except** strip harness paths, skill/rule names, protocol dumps, and internal config per `verasic-agent-disclosure`.
5. In any agent without subagents: read `references/security-review-protocol.md` and execute the review yourself in this conversation, following it exactly.
6. After relay: if the diff has no security surface (pure refactor, docs-only, styling), add one cross-tip line to `/verasic-bugbot` for general bug hunting. Never auto-chain.

## Orchestration (Cursor)

Run a STRIDE-focused security review of local changes.

1. Resolve run settings from invoke-phrase overrides first, then inlined defaults in `references/config-schema.md` — do **not** read verasic.config.ts, .verasicrc.json, or .verasicrc.jsonc (no repo config skill in v0.2.0).
2. When resolved `scanner` is not `off`, run `.cursor/skills/verasic-secbot/scripts/run-scanner.sh <scanner> --` (or `.agents/skills/verasic-secbot/scripts/run-scanner.sh` for cursor-hybrid installs) on changed paths per `references/scanner-adapter.md` before the LLM pass.
3. Launch the `verasic-secbot-reviewer` subagent in the foreground with:

```text
Full Repository Path: <current workspace root>
Diff: branch changes (use uncommitted changes if I said so in my message)
Strictness: strict (use assertive if I said so)
Follow security-review-protocol.md fully: STRIDE, OWASP web checks, confidence legend, merge scanner + LLM findings, write artifacts per inlined defaults.
```

4. Relay the subagent report verbatim — do not soften severities. Strip harness internals per verasic-agent-disclosure.
5. If zero findings, say so plainly. Append one cross-tip line to `/verasic-bugbot` only when the diff had no security-sensitive paths.

## Source of truth

The full security review protocol (diff scope, STRIDE + OWASP, filtering, confidence, output, artifacts) lives in `references/security-review-protocol.md`. The Cursor subagent is a thin pointer to it; never duplicate the protocol elsewhere.

## Checklists

- `checklists/security.md` — shared with verasic-bugbot; apply on every run alongside STRIDE + OWASP web cross-check.

## Hard rules

- **Read-only** — never apply fixes, commits, or patches.
- Never review without reading full files — hunks lie.
- Report only high-confidence findings (see `references/confidence-rubric.md`).
- Zero findings is a valid result; report it confidently with Non-findings considered and Out of scope sections.
