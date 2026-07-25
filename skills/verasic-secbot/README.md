# Verasic Secbot

STRIDE security review on git diffs — optional deterministic scanner (OpenGrep / Semgrep),
high-confidence filtering, and markdown artifacts under `verasic/` and `.verasic/`.
Read-only: reports findings, never applies fixes.

## Parts

Paths relative to this skill folder unless noted. After `setup.sh`, skill files
live under `.cursor/skills/verasic-secbot/`.

| File                                      | Role                                             |
| ----------------------------------------- | ------------------------------------------------ |
| `references/security-review-protocol.md`  | The brain — single source of truth               |
| `references/confidence-rubric.md`         | 0–10 confidence scale and floors                 |
| `references/scanner-adapter.md`           | OpenGrep / Semgrep / auto / off                  |
| `references/config-schema.md`             | Secbot-local defaults (inlined)                  |
| `checklists/security.md`                  | Shared security checklist (with verasic-bugbot)  |
| `SKILL.md`                                | Auto-trigger + orchestration                     |
| `.cursor/agents/verasic-secbot-reviewer.md` | Cursor subagent (after `setup.sh`)           |

## Human workflow

- **`/verasic-secbot`** (skill) — STRIDE security review of branch changes. Add "uncommitted only" to review staged + unstaged, or invoke phrases like "assertive mode on auth changes".
- **`/verasic-secbot-reviewer`** (agent) — talks to the secbot subagent directly in isolated context.

Day-to-day loop:

1. Finish auth, API, webhook, or crypto changes.
2. Run `/verasic-secbot` (or say "security review my changes").
3. Fix CRITICAL/HIGH findings, re-run until `✅ No security issues found`.
4. Optionally run `/verasic-bugbot` for general bug hunting (sibling skill — not auto-chained).
5. Commit / open PR; promote artifacts to `verasic/security-reviews/` when team-visible.

## Output

Legend (severity + confidence bands), summary table, then expanded finding blocks with
Category, Exploit, Reachability, and Remediation. Artifacts written per `report.promote` default.

Security: [references/scanner-notes.md](references/scanner-notes.md) · upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md)

## Defaults

Inlined in `references/config-schema.md` — scanner `off`, strictness `strict`, artifacts to both `localDir` and `trackedDir`. Override via invoke phrase.

## Install into a new project

From the project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

or skill-only (any agent, not just Cursor): `npx skills add Milkywayrules/verasic-skills`
