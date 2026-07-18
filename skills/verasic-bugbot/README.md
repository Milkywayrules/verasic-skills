# Verasic Bugbot

Bugbot-like code review that runs locally in Cursor — no Bugbot subscription needed.
Reviews git diffs for real bugs (logic, security, races, perf) with an aggressive
low-noise filter. Style nitpicks are never reported.

## Parts

| File                                 | Role                                  |
| ------------------------------------ | ------------------------------------- |
| `.cursor/agents/verasic-bugbot.md`   | The review subagent — core logic      |
| `.cursor/commands/verasic-review.md` | `/verasic-review` slash command       |
| `.cursor/skills/verasic-bugbot/`     | This skill: auto-trigger + checklists |

## Usage

- `/verasic-review` — review branch changes vs default branch
- `/verasic-review uncommitted` — review staged + unstaged only
- Or just say "bugbot review my changes" in chat

## Output

One-line verdict (`✅` / `🐛`), then issues ranked CRITICAL / HIGH / MEDIUM,
each with file:line, evidence from the code, and a concrete fix.

## Extend per project

Drop extra `.md` checklists into `checklists/` (e.g. `nextjs.md`, `infra.md`) —
the subagent applies every file in that folder automatically.

## Install into a new project

From the project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

or skill-only (any agent, not just Cursor): `npx skills add Milkywayrules/verasic-skills`
