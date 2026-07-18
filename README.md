# verasic-skills

Agent skills by Verasic Labs. Currently ships **verasic-bugbot**: Bugbot-like
code review that runs locally in your AI agent — no Bugbot subscription needed.
It reviews git diffs for real bugs (logic, security, races, perf) with an
aggressive low-noise filter. Style nitpicks are never reported.

## Install

**Cursor (full setup: subagent + slash command + skill)** — from your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

Re-run the same command anytime to update. Then use `/verasic-review` in chat.

**Any agent (skill only — Claude Code, Codex, etc.):**

```bash
npx skills add Milkywayrules/verasic-skills
```

## Usage

- `/verasic-review` — review branch changes vs the default branch
- `/verasic-review uncommitted` — review staged + unstaged only
- Or just say "bugbot review my changes"

Full docs: [skills/verasic-bugbot/README.md](skills/verasic-bugbot/README.md)

## This Repo Hierarchy

```markdown
verasic-skills/
├── README.md # root: short pitch + install commands
├── setup.sh
├── skills/
│ └── verasic-bugbot/ # ← the unit npx installs
│ ├── SKILL.md
│ ├── README.md
│ ├── references/
│ │ └── review-protocol.md # ← single source of truth
│ └── checklists/
│ ├── correctness.md
│ ├── security.md
│ └── performance.md
└── cursor/
├── agents/verasic-bugbot.md # thin pointer to the protocol
└── commands/verasic-review.md
```
