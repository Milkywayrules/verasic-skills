# verasic-skills

Agent skills by Verasic Labs, built for AI-assisted development workflows.

- **verasic-bugbot** — Bugbot-like code review that runs locally in your AI
  agent, no Bugbot subscription needed. Reviews git diffs for real bugs
  (logic, security, races, perf) with an aggressive low-noise filter. Style
  nitpicks are never reported.
- **verasic-git-commits** — hard commit convention plus pre-push history
  audit. One message style for humans and agents, no co-authored/AI trailers,
  no AI-session language in messages.
- **verasic-github-env** — GitHub CLI auth for local agent harnesses.
  Fine-grained PAT per repo in gitignored `.github-agent.local`, optional direnv,
  bootstrap + verify scripts. Separate tiers for CI and production secrets.
- **verasic-init** — one-command repo wiring for whichever verasic skills
  are installed. Detects, runs each skill's own wiring script idempotently,
  prints a single setup report. Built for skills.sh installs where `setup.sh`
  never runs.

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
- `/verasic-init` — wire every installed verasic skill into the repo (cherry-pick with `--skills a,b`)
- `/verasic-setup-github` — bootstrap GitHub CLI auth for local agents (`.envrc`, `.env.example`, verify)
- Commit convention needs no invocation — the always-applied rule enforces it on every commit
- GitHub env rule applies automatically before `gh` commands when installed

Full docs: [skills/verasic-bugbot/README.md](skills/verasic-bugbot/README.md) ·
[skills/verasic-git-commits/README.md](skills/verasic-git-commits/README.md) ·
[skills/verasic-github-env/README.md](skills/verasic-github-env/README.md) ·
[skills/verasic-init/README.md](skills/verasic-init/README.md)

## This Repo Hierarchy

```markdown
verasic-skills/
├── README.md                          # root: short pitch + install commands
├── .gitignore
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
│   ├── verasic-git-commits/
│   │   ├── SKILL.md
│   │   ├── README.md
│   │   ├── hooks/
│   │   │   └── commit-msg             # deterministic layer: strip trailers, reject style breaks
│   │   ├── scripts/
│   │   │   └── test-regression.sh     # disposable regression tests
│   │   └── references/
│   │       ├── conventions.md         # ← single source of truth (the spec)
│   │       ├── commit-protocol.md     # write path: workflow, verify, escape hatch
│   │       └── audit-protocol.md      # read path: scope, checks, report
│   ├── verasic-github-env/
│   │   ├── SKILL.md
│   │   ├── README.md
│   │   ├── scripts/
│   │   │   ├── bootstrap.sh           # wire repo: .envrc, templates, .gitignore
│   │   │   ├── check-gh.sh            # verify GH_TOKEN + gh auth
│   │   │   ├── load-gh-env.sh         # safe GH var loader
│   │   │   ├── parse-gh-repo.sh       # owner/repo from git remote URL
│   │   │   └── test-regression.sh     # disposable regression tests
│   │   ├── templates/
│   │   │   ├── .envrc
│   │   │   └── github-agent.local.example
│   │   └── references/
│   │       └── setup-protocol.md      # ← single source of truth
│   └── verasic-init/
│       ├── SKILL.md
│       ├── README.md
│       ├── manifest.txt               # registry: skill → wiring script
│       ├── scripts/
│       │   ├── init.sh                # detect installed skills, wire, report
│       │   └── test-regression.sh
│       └── references/
│           └── init-protocol.md       # ← single source of truth
└── cursor/
    ├── agents/
    │   ├── verasic-bugbot.md          # thin pointer to the review protocol
    │   └── verasic-commit-auditor.md  # thin pointer to the audit protocol
    ├── commands/
    │   ├── verasic-review.md
    │   ├── verasic-audit-commits.md
    │   ├── verasic-setup-github.md
    │   └── verasic-init.md
    └── rules/
        ├── verasic-git-commits.mdc    # always-applied digest + pointer
        └── verasic-github-env.mdc
```
