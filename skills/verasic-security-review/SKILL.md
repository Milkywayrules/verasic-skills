---
name: verasic-security-review
description: STRIDE security review on git diff with optional deterministic scanner. Use when the user asks to "security review", "review for security", "STRIDE review", "check my diff for vulnerabilities", or before commit/PR when auth, crypto, webhooks, or untrusted input changed.
---

Security: see `references/scanner-notes.md` and upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md) for expected scanner signals and trust model.

# Verasic Security Review — Orchestration

## Workflow

1. Determine scope from the user's message: branch changes (default) or overrides (`uncommitted only`, `staged only`, `against <branch>`). Invoke phrase beats config when both set.
2. Read config via `bash .cursor/skills/verasic-config/scripts/resolve-config.sh` (or `.agents/skills/verasic-config/scripts/resolve-config.sh` for cursor-hybrid installs): `verasic.config.ts` → `.verasicrc.jsonc` → `.verasicrc.json` → defaults per `references/config-schema.md`. Resolve `securityReview.scanner`, `strictness`, artifact paths, and `report.promote`.
3. Optional scanner: when `scanner` is not `off`, run `scripts/run-scanner.sh <scanner> --` on changed source paths only (see `references/scanner-adapter.md`). Scanner missing → one-line skip, continue.
4. In Cursor: launch the `verasic-security-reviewer` subagent (`.cursor/agents/verasic-security-reviewer.md` or `.agents/cursor/agents/verasic-security-reviewer.md` for cursor-hybrid installs) with repository path, scope, scanner results (if any), and config — in the **foreground**. Relay its report unchanged **except** strip harness paths, skill/rule names, protocol dumps, and internal config per `verasic-agent-disclosure`.
5. In any agent without subagents: read `references/security-review-protocol.md` and execute the review yourself in this conversation, following it exactly.
6. After relay: if the diff has no security surface (pure refactor, docs-only, styling), add one cross-tip line to `/verasic-review` for general bug hunting. Never auto-chain.

## Source of truth

The full security review protocol (diff scope, STRIDE + OWASP, filtering, confidence, output, artifacts) lives in `references/security-review-protocol.md`. The Cursor subagent is a thin pointer to it; never duplicate the protocol elsewhere.

## Checklists

- `checklists/security.md` — shared with verasic-bugbot; apply on every run alongside STRIDE + OWASP web cross-check.

## Hard rules

- **Read-only** — never apply fixes, commits, or patches.
- Never review without reading full files — hunks lie.
- Report only high-confidence findings (see `references/confidence-rubric.md`).
- Zero findings is a valid result; report it confidently with Non-findings considered and Out of scope sections.
