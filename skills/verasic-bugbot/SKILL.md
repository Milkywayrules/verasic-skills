---
name: verasic-bugbot
description: Bugbot-like local code review. Use when the user asks to "review changes", "bugbot review", "check my diff", "find bugs in my changes", or after completing a significant code change and wanting verification before commit/PR.
---

# Verasic Bugbot — Local Review Orchestration

## Workflow

1. Determine scope from the user's message: branch changes (default) or uncommitted changes.
2. Launch the `verasic-bugbot` subagent (in `.cursor/agents/verasic-bugbot.md`) with the repository path and scope. Run it in the foreground.
3. Relay the subagent's report to the user unchanged.

## Checklists (used by the subagent)

Modular checklists live in `checklists/`:

- `checklists/correctness.md` — logic, edge cases, contracts, concurrency
- `checklists/security.md` — injection, secrets, authz, unsafe deserialization
- `checklists/performance.md` — N+1, unbounded growth, blocking calls

Add project-specific checklists as new files here; the subagent applies every `.md` file in `checklists/`.

## Hard rules

- Never review without reading full files — hunks lie.
- Never report style/nitpicks. Real bugs only.
- Zero findings is a valid result; report it confidently.
