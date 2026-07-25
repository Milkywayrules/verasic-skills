# Verasic Bugbot

Bugbot-like code review that runs locally in Cursor — no Bugbot subscription needed.
Reviews git diffs for real bugs (logic, security, races, perf) with an aggressive
low-noise filter. Style nitpicks are never reported.

## Parts

Paths relative to this skill folder unless noted. After `setup.sh`, skill files
live under `.cursor/skills/verasic-bugbot/`.

| File                                      | Role                                             |
| ----------------------------------------- | ------------------------------------------------ |
| `references/review-protocol.md`           | The brain — single source of truth               |
| `checklists/`                             | Modular bug-hunting checklists                   |
| `SKILL.md`                                | Auto-trigger + orchestration                     |
| `.cursor/agents/verasic-bugbot-reviewer.md` | Cursor subagent (after init fetch or manual) |

## Human workflow (which slash entry do I use?)

Typing `/verasic` in Cursor chat shows skill and agent entries:

- **`/verasic-bugbot`** (skill) — primary entry. Reviews branch changes (default) or
  uncommitted when you say so. Orchestration spawns the reviewer subagent.
- **`/verasic-bugbot-reviewer`** (agent) — talks to the review subagent directly in
  isolated context. Rarely needed; the skill launches it for you.

Canonical map: [references/verasic-cursor-map.md](../../references/verasic-cursor-map.md).

Day-to-day loop:

1. Finish a feature/fix.
2. Run `/verasic-bugbot` (or say "bugbot review my changes").
3. Fix CRITICAL/HIGH findings, re-run until `✅ No issues found`.
4. Commit / open PR.

For auth, crypto, webhooks, or input-validation changes, the orchestrator may tip
`/verasic-secbot` for STRIDE depth — never auto-chained.

## Output

One-line verdict (`✅` / `🐛`), then issues ranked CRITICAL / HIGH / MEDIUM,
each with file:line, evidence from the code, and a concrete fix.

Security: [references/scanner-notes.md](references/scanner-notes.md) · upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md)

## Extend per project

Drop extra `.md` checklists into `checklists/` (e.g. `laravel.md`, `flutter.md`) —
the protocol applies every file in that folder automatically, and the reviewer
will tip you when your repo's stack has no matching checklist yet.

Custom checklists are safe across updates: re-running `setup.sh` overwrites
shipped skill files (including any local edits to them); extra files you added
(e.g. custom checklists in `checklists/`) survive. Commit them with the
project; if one proves useful across projects, promote it upstream to the
`verasic-skills` repo so every install gets it.

## Install into a new project

From the project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

or skill-only (any agent, not just Cursor): `npx skills add Milkywayrules/verasic-skills`
