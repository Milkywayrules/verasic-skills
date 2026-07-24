---
name: verasic-bugbot
description: Bugbot-like local code review. Use when the user asks to "review changes", "bugbot review", "check my diff", "find bugs in my changes", or after completing a significant code change and wanting verification before commit/PR.
---

Security: see `references/scanner-notes.md` and upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md) for expected scanner signals and trust model.

# Verasic Bugbot — Local Review Orchestration

## Workflow

1. Determine scope from the user's message: branch changes (default) or uncommitted changes. A narrower user request (e.g. "only the API layer") filters which findings to report — the diff scope stays one of the two above.
2. In Cursor: launch the `verasic-bug-reviewer` subagent (`.cursor/agents/verasic-bug-reviewer.md` or `.agents/skills/` layout) with the repository path and scope, in the foreground, then relay its report unchanged **except** strip harness paths, skill/rule names, protocol dumps, and internal config per `verasic-agent-disclosure`.
3. After relay: if the diff touches auth, crypto, webhooks, or user-input validation, add one cross-tip line to `/verasic-security-review` for STRIDE depth. Never auto-chain.
4. In any agent without subagents: read `references/review-protocol.md` and execute the review yourself in this conversation, following it exactly.

## Source of truth

The full review protocol (diff scope, process, filtering, output format) lives in `references/review-protocol.md`. The Cursor subagent is a thin pointer to it; never duplicate the protocol elsewhere.

## Checklists (used by the protocol)

Modular checklists live in `checklists/`:

- `checklists/correctness.md` — logic, edge cases, contracts, concurrency
- `checklists/security.md` — injection, secrets, authz, unsafe deserialization
- `checklists/performance.md` — N+1, unbounded growth, blocking calls
- `checklists/infra.md` — Docker/compose/CI/proxy: exposed ports, secrets, data loss

Add project-specific checklists as new files here; the protocol applies every `.md` file in `checklists/`.

## Hard rules

- Never review without reading full files — hunks lie.
- Never report style/nitpicks. Real bugs only.
- Zero findings is a valid result; report it confidently.
