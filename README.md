# verasic-skills

Agent skills by Verasic Labs, built for AI-assisted development workflows.

- **verasic-bugbot** — Bugbot-like code review that runs locally in your AI
  agent, no Bugbot subscription needed. Reviews git diffs for real bugs
  (logic, security, races, perf) with an aggressive low-noise filter. Style
  nitpicks are never reported.
- **verasic-git-commits** — hard commit convention plus pre-push history
  audit. One message style for humans and agents, no co-authored/AI trailers,
  no AI-session language in messages.

## Install

**Cursor (full setup: rules + subagents + slash commands + skills)** — from your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

Re-run the same command anytime to update.

**Any agent (skills only — Claude Code, Codex, etc.):**

```bash
npx skills add Milkywayrules/verasic-skills
```

## Usage

- `/verasic-review` — review branch changes vs the default branch
- `/verasic-review uncommitted` — review staged + unstaged only
- `/verasic-audit-commits` — audit branch commit history before push/PR
- Commit convention needs no invocation — the always-applied rule enforces it on every commit

Full docs: [skills/verasic-bugbot/README.md](skills/verasic-bugbot/README.md) ·
[skills/verasic-git-commits/README.md](skills/verasic-git-commits/README.md)

## This Repo Hierarchy

```markdown
verasic-skills/
├── README.md                          # root: short pitch + install commands
├── setup.sh
├── skills/                            # ← the units npx installs
│   ├── verasic-bugbot/
│   │   ├── SKILL.md
│   │   ├── README.md
│   │   ├── references/
│   │   │   └── review-protocol.md     # ← single source of truth
│   │   └── checklists/
│   │       ├── correctness.md
│   │       ├── security.md
│   │       ├── performance.md
│   │       └── infra.md
│   └── verasic-git-commits/
│       ├── SKILL.md
│       ├── README.md
│       └── references/
│           ├── conventions.md         # ← single source of truth (the spec)
│           ├── commit-protocol.md     # write path: workflow, verify, escape hatch
│           └── audit-protocol.md      # read path: scope, checks, report
└── cursor/
    ├── agents/
    │   ├── verasic-bugbot.md          # thin pointer to the review protocol
    │   └── verasic-commit-auditor.md  # thin pointer to the audit protocol
    ├── commands/
    │   ├── verasic-review.md
    │   └── verasic-audit-commits.md
    └── rules/
        └── verasic-git-commits.mdc    # always-applied digest + pointer
```
