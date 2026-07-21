# verasic-skills

Agent skills by Verasic Labs, built for AI-assisted development workflows.

- **verasic-bugbot** — Bugbot-like code review that runs locally in your AI
  agent, no Bugbot subscription needed. Reviews git diffs for real bugs
  (logic, security, races, perf) with an aggressive low-noise filter. Style
  nitpicks are never reported.
- **verasic-fusion** — multi-model fusion for exploration and decision support.
  Run the same question across models you name, with optional templates
  (board-verdict, rfc-review, tradeoff-matrix, and more). Main agent orchestrates;
  conflicts and provenance stay visible.
- **verasic-git-commits** — hard commit convention plus pre-push history
  audit. One message style for humans and agents, no co-authored/AI trailers,
  no AI-session language in messages.
- **verasic-github-env** — GitHub CLI auth for local agent harnesses.
  Fine-grained PAT per repo in gitignored `.github-agent.local`, optional direnv,
  bootstrap + verify scripts. Separate tiers for CI and production secrets.
- **verasic-init** — one-command repo wiring for whichever verasic skills
  are installed. Detects, runs each skill's own wiring script idempotently,
  optional manifest verify and integrity hash checks, prints a single setup report. Built for skills.sh installs where `setup.sh`
  never runs.

## Install

**Cursor (full setup: rules + subagents + slash commands + skills)** — from your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

Re-run the same command anytime to update (it overwrites shipped files; extra files you added survive).

**Any agent (skills only — Claude Code, Codex, etc.):**

```bash
npx skills add Milkywayrules/verasic-skills
```

**Then wire the repo (both install paths, once):** run `/verasic-init` in Cursor, or directly:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh   # adjust the prefix if your agent installs skills elsewhere (e.g. .agents/skills/)
```

It detects the installed skills, wires each one idempotently, and prints a report — after that, everything enforces itself.

## Usage

- `/verasic-fusion` — multi-model fusion (requires `mode`, `models`, question)
- `/verasic-review` — review branch changes vs the default branch
- `/verasic-review uncommitted` — review staged + unstaged only
- `/verasic-audit-commits` — audit branch commit history before push/PR
- `/verasic-init` — wire every installed verasic skill into the repo (cherry-pick with `--skills a,b`)
- `/verasic-setup-github` — bootstrap GitHub CLI auth for local agents (`.envrc`, `.env.example`, verify)
- Commit convention needs no invocation — the always-applied rule enforces it on every commit
- GitHub env rule applies automatically before `gh` commands when installed

Full docs: [skills/verasic-fusion/README.md](skills/verasic-fusion/README.md) ·
[skills/verasic-bugbot/README.md](skills/verasic-bugbot/README.md) ·
[skills/verasic-git-commits/README.md](skills/verasic-git-commits/README.md) ·
[skills/verasic-github-env/README.md](skills/verasic-github-env/README.md) ·
[skills/verasic-init/README.md](skills/verasic-init/README.md)

## Testing

Most skills ship a local `test-regression.sh` — run before publish, no CI required.
**verasic-fusion** is the exception: it also has `test-exhaustive-protocol.sh`,
`test-exhaustive.sh` (local full gate), and `.github/workflows/verasic-fusion.yml`
(structural + protocol checks on push).

## This Repo Hierarchy

```markdown
verasic-skills/
├── README.md # root: short pitch + install commands
├── versions.lock # pinned skill semver for releases
├── .gitignore
├── setup.sh
├── .github/workflows/
│ └── verasic-fusion.yml # CI: fusion structural + protocol checks only
├── skills/ # ← the units npx installs
│ ├── verasic-bugbot/
│ │ ├── SKILL.md
│ │ ├── README.md
│ │ ├── references/
│ │ │ └── review-protocol.md # ← single source of truth
│ │ └── checklists/
│ │ ├── correctness.md
│ │ ├── security.md
│ │ ├── performance.md
│ │ └── infra.md
│ ├── verasic-fusion/
│ │ ├── SKILL.md
│ │ ├── README.md
│ │ ├── references/
│ │ │ ├── fusion-protocol.md # ← single source of truth
│ │ │ ├── helper.md
│ │ │ ├── models.md
│ │ │ └── use-cases.md
│ │ ├── templates/
│ │ │ ├── board-verdict.md
│ │ │ ├── rfc-review.md
│ │ │ ├── tradeoff-matrix.md
│ │ │ ├── research-brief.md
│ │ │ ├── risk-register.md
│ │ │ ├── devils-advocate.md
│ │ │ ├── premortem.md
│ │ │ ├── stakeholder-lens.md
│ │ │ └── compare-to-status-quo.md
│ │ └── scripts/
│ │ ├── test-regression.sh
│ │ ├── test-exhaustive-protocol.sh
│ │ └── test-exhaustive.sh # local full gate (includes init regression in source tree)
│ ├── verasic-git-commits/
│ │ ├── SKILL.md
│ │ ├── README.md
│ │ ├── hooks/
│ │ │ └── commit-msg # deterministic layer: strip trailers, reject style breaks
│ │ ├── scripts/
│ │ │ ├── wire-hook.sh # hook wiring used by verasic-init
│ │ │ └── test-regression.sh # disposable regression tests
│ │ └── references/
│ │ ├── conventions.md # ← single source of truth (the spec)
│ │ ├── commit-protocol.md # write path: workflow, verify, escape hatch
│ │ └── audit-protocol.md # read path: scope, checks, report
│ ├── verasic-github-env/
│ │ ├── SKILL.md
│ │ ├── README.md
│ │ ├── scripts/
│ │ │ ├── bootstrap.sh # wire repo: .envrc, templates, .gitignore
│ │ │ ├── check-gh.sh # verify GH_TOKEN + gh auth
│ │ │ ├── load-gh-env.sh # safe GH var loader
│ │ │ ├── parse-gh-repo.sh # owner/repo from git remote URL
│ │ │ └── test-regression.sh # disposable regression tests
│ │ ├── templates/
│ │ │ ├── .envrc
│ │ │ └── github-agent.local.example
│ │ └── references/
│ │ └── setup-protocol.md # ← single source of truth
│ └── verasic-init/
│ ├── SKILL.md
│ ├── README.md
│ ├── manifest.txt # registry: skill → wire → verify → description
│ ├── VERSION
│ ├── integrity.sha256
│ ├── scripts/
│ │ ├── init.sh # detect installed skills, wire, report
│ │ └── test-regression.sh
│ └── references/
│ └── init-protocol.md # ← single source of truth
└── cursor/
├── agents/
│ ├── verasic-bugbot.md # thin pointer to the review protocol
│ └── verasic-commit-auditor.md # thin pointer to the audit protocol
├── commands/
│ ├── verasic-review.md
│ ├── verasic-fusion.md
│ ├── verasic-audit-commits.md
│ ├── verasic-setup-github.md
│ └── verasic-init.md
└── rules/
├── verasic-git-commits.mdc # always-applied digest + pointer
└── verasic-github-env.mdc
```
