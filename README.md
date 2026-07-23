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
- **verasic-deep-research** — verified deep research with source ledger,
  verify-before-cite, 5-axis confidence scoring, and optional drill rounds.
  T2 workers (Hunter, Practitioner, Skeptic, Arbiter) plus optional T3 fetch.
- **verasic-git-commits** — hard commit convention plus pre-push history
  audit. One message style for humans and agents, no co-authored/AI trailers,
  no AI-session language in messages.
- **verasic-github-env** — GitHub CLI auth for local agent harnesses.
  Fine-grained PAT per repo in gitignored `.github-agent.local`, optional direnv,
  bootstrap + verify scripts. Separate tiers for CI and production secrets.
- **verasic-init** — confirm-first repo setup for installed verasic skills: plan (profile, checklist, usage), then `--yes` to wire repo-level enforcement and optionally fetch Cursor UX from upstream. Built for skills.sh installs where `setup.sh` never runs.

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

**Cursor + skills CLI (skills in `.agents/skills/`):**

```bash
npx skills add Milkywayrules/verasic-skills
bash .agents/skills/verasic-init/scripts/init.sh --yes --profile cursor-hybrid   # fetches Cursor UX from upstream
```

Manual copy (optional — same result as hybrid fetch):

```bash
git clone --depth 1 https://github.com/Milkywayrules/verasic-skills /tmp/verasic-skills
mkdir -p .cursor/agents .cursor/commands .cursor/rules
cp -r /tmp/verasic-skills/cursor/agents/.   .cursor/agents/
cp -r /tmp/verasic-skills/cursor/commands/. .cursor/commands/
cp -r /tmp/verasic-skills/cursor/rules/.    .cursor/rules/
```

Slash commands reference `.cursor/skills/…` by default; when skills live under
`.agents/skills/`, the agent adjusts the path prefix (stated in each command file).

**Then set up the repo (all install paths):** run `/verasic-init` in Cursor — it shows a **plan first** (profile, checklist, usage), then apply with `--yes` after you confirm. Or directly:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh              # plan only (default)
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor   # apply
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile agent    # skills.sh / Claude Code / Codex / Kiro / …
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor-hybrid  # npx skills + Cursor UX
```

Adjust the skills path prefix if your agent installs elsewhere (e.g. `.agents/skills/`). Profile spec ships in the skill: `references/install-profiles.md`. Cursor/hybrid profiles fetch UX from upstream on `--yes` (network required).

## Usage

- `/verasic-fusion` — multi-model fusion (requires `mode`, `models`, question)
- `/verasic-deep-research` — ledger-backed research (requires `depth`, `output`, `source-boundary`, question)
- `/verasic-review` — review branch changes vs the default branch
- `/verasic-review uncommitted` — review staged + unstaged only
- `/verasic-audit-commits` — audit branch commit history before push/PR
- `/verasic-init` — plan setup (profile + checklist + usage), then apply with `--yes` after you confirm
- `/verasic-setup-github` — bootstrap GitHub CLI auth for local agents (`.envrc`, `.env.example`, verify)
- Commit convention needs no invocation — the always-applied rule enforces it on every commit
- GitHub env rule applies automatically before `gh` commands when installed

Full docs: [skills/verasic-fusion/README.md](skills/verasic-fusion/README.md) ·
[skills/verasic-deep-research/README.md](skills/verasic-deep-research/README.md) ·
[skills/verasic-bugbot/README.md](skills/verasic-bugbot/README.md) ·
[skills/verasic-git-commits/README.md](skills/verasic-git-commits/README.md) ·
[skills/verasic-github-env/README.md](skills/verasic-github-env/README.md) ·
[skills/verasic-init/README.md](skills/verasic-init/README.md)

## Security

Static scanners (Gen, Socket, Snyk on [skills.sh](https://skills.sh/milkywayrules/verasic-skills))
often flag harness skills for expected reasons — git hooks, credential docs, `curl` update checks.
See [SECURITY.md](SECURITY.md) for the trust model, expected scan signals, and credential handling.
Per-skill scanner notes:
[verasic-init](skills/verasic-init/references/scanner-notes.md) ·
[verasic-github-env](skills/verasic-github-env/references/scanner-notes.md) ·
[verasic-git-commits](skills/verasic-git-commits/references/scanner-notes.md) ·
[verasic-fusion](skills/verasic-fusion/references/scanner-notes.md) ·
[verasic-deep-research](skills/verasic-deep-research/references/scanner-notes.md) ·
[verasic-bugbot](skills/verasic-bugbot/references/scanner-notes.md)

## Testing

Most skills ship a local `test-regression.sh` — run before publish, no CI required.
**verasic-fusion** and **verasic-deep-research** also ship protocol exhaustive tests and
GitHub Actions workflows. **Version manifest** is enforced repo-wide — see [Versioning](#versioning).
`bash scripts/check-references.sh` validates concrete internal path references in markdown
(backtick paths, local file links) — run via `test-all.sh` and CI after version gates.

## Versioning

**Independent skill versioning:** git tags (`vX.Y.Z`) are bundle snapshots; each skill has its
own semver in `skills/<name>/VERSION`. Root `versions.lock` must match every manifest skill —
enforced by CI.

```bash
bash scripts/check-versions.sh          # release gate (lock ↔ VERSION ↔ integrity)
bash scripts/refresh-integrity.sh <skill>  # after VERSION or integrity.txt changes
bash scripts/test-all.sh                  # full automated router (local + tag CI)
```

Full release checklist: [references/release-protocol.md](references/release-protocol.md).

After install, `verasic-init --list` shows local `VERSION` per skill. Strict integrity (default)
hashes `VERSION` in `integrity.sha256` — tamper or stale bump fails as `broken install`.

## This Repo Hierarchy

```markdown
verasic-skills/
├── README.md # root: short pitch + install commands
├── SECURITY.md # trust model, scanner signals, credential handling
├── versions.lock # release manifest — must match skills/*/VERSION (CI enforced)
├── scripts/
│ ├── check-versions.sh # lock ↔ VERSION ↔ integrity gate
│ ├── check-references.sh # validate markdown internal path refs
│ ├── check-cursor-ux-manifest.sh # cursor/ ↔ cursor-ux-manifest sync gate
│ ├── refresh-integrity.sh # regenerate integrity.sha256 after bumps
│ ├── test-all.sh # router: all regressions + version + protocol gates
│ └── test-versions-regression.sh
├── references/
│ ├── release-protocol.md # release checklist (version + integrity)
│ ├── release-notes-template.md # GitHub Release body template
│ └── repo-meta.md # branch protection + maintainer settings
├── CHANGELOG.md # bundle release summary
├── setup.sh
├── .github/workflows/
│ ├── verasic-fusion.yml
│ ├── verasic-deep-research.yml
│ ├── verasic-init.yml
│ ├── verasic-git-commits.yml
│ ├── verasic-release.yml # full test-all on tag push
│ └── verasic-versions.yml # version manifest on every main PR/push
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
│ │ │ ├── brief-research.md
│ │ │ ├── risk-register.md
│ │ │ ├── devils-advocate.md
│ │ │ ├── premortem.md
│ │ │ ├── stakeholder-lens.md
│ │ │ └── compare-to-status-quo.md
│ │ └── scripts/
│ │ ├── test-regression.sh
│ │ ├── test-exhaustive-protocol.sh
│ │ └── test-exhaustive.sh # local full gate (includes init regression in source tree)
│ ├── verasic-deep-research/
│ │ ├── SKILL.md
│ │ ├── README.md
│ │ ├── references/
│ │ │ ├── research-protocol.md # ← single source of truth
│ │ │ ├── helper.md
│ │ │ ├── citation-protocol.md
│ │ │ ├── confidence-rubric.md
│ │ │ ├── drill-protocol.md
│ │ │ ├── source-tiers.md
│ │ │ ├── fusion-handoff.md
│ │ │ └── scanner-notes.md
│ │ ├── templates/
│ │ │ ├── deep-research-brief.md
│ │ │ └── source-ledger.yaml
│ │ └── workflows/
│ │     ├── quick-scan.md
│ │     ├── standard-research.md
│ │     ├── adversarial-deep.md
│ │     └── custom.md
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
│ │ ├── init.sh # plan + wire + report
│ │ ├── profile.sh # profile detect, upstream UX fetch
│ │ └── test-regression.sh
│ └── references/
│ ├── init-protocol.md # ← single source of truth
│ ├── install-profiles.md
│ └── cursor-ux-manifest.txt
└── cursor/
    ├── agents/
    │ ├── verasic-bugbot.md # thin pointer to the review protocol
    │ └── verasic-commit-auditor.md # thin pointer to the audit protocol
    ├── commands/
    │ ├── verasic-review.md
    │ ├── verasic-fusion.md
    │ ├── verasic-deep-research.md
    │ ├── verasic-audit-commits.md
    │ ├── verasic-setup-github.md
    │ └── verasic-init.md
    └── rules/
        ├── verasic-git-commits.mdc # always-applied digest + pointer
        └── verasic-github-env.mdc
```
