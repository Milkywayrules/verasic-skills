# verasic-skills

Agent skills by Verasic Labs, built for AI-assisted development workflows.

- **verasic-bugbot** — Bugbot-like code review that runs locally in your AI
  agent, no Bugbot subscription needed. Reviews git diffs for real bugs
  (logic, security, races, perf) with an aggressive low-noise filter. Style
  nitpicks are never reported.
- **verasic-secbot** — STRIDE-focused security review on git diff with
  optional Semgrep/OpenGrep scanner pass, confidence scoring, and artifact output.
  Complements bugbot — depth on auth, crypto, webhooks, and input validation.
- **verasic-fusion** — multi-model fusion for exploration and decision support.
  Run the same question across models you name, with optional templates
  (board-verdict, rfc-review, tradeoff-matrix, and more). Main agent orchestrates;
  conflicts and provenance stay visible.
- **verasic-deep-research** — verified deep research with source ledger,
  verify-before-cite, 5-axis confidence scoring, and optional drill rounds.
  T2 workers (Hunter, Practitioner, Skeptic, Arbiter) plus optional T3 fetch.
- **verasic-git-commits-convention** — hard commit convention plus deterministic
  commit-msg hook. One message style for humans and agents, no co-authored/AI trailers,
  no AI-session language in messages.
- **verasic-git-commits-audit** — pre-push commit history audit (spawn auditor subagent).
- **verasic-agent-disclosure** — block harness, skill, router, and protocol
  leaks in user-facing responses. Always-on disclosure rule plus adversarial
  red-team catalog for regression (~8 min on demand).
- **verasic-github-cli-init** — GitHub CLI auth for local agent harnesses.
  Fine-grained PAT per repo in gitignored `.github-agent.local`, optional direnv,
  bootstrap + verify scripts. Separate tiers for CI and production secrets.
- **verasic-github-governance** — GitHub repo governance factory: CI bootstrap,
  lefthook hooks, doctor checks, plan-gated hard protection. Soft-first for Free
  private repos; OpenTofu hard path lives in dogfood registry repos only.
- **verasic-github-governance-init** — plan-first orchestrator for governance
  bootstrap (`/verasic-github-governance-init`). Runs factory plan, then `--yes` to apply.
- **verasic-init** — confirm-first repo setup for installed verasic skills: plan (profile, checklist, usage), then `--yes` to wire repo-level enforcement and optionally fetch Cursor UX from upstream. Built for skills.sh installs where `setup.sh` never runs.

**Slash map (canonical):** [references/verasic-cursor-map.md](references/verasic-cursor-map.md)

## Install

**Cursor (full setup: rules + subagents + skills)** — from your project root:

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

Manual copy (optional — same result as hybrid fetch for agents + rules):

```bash
git clone --depth 1 https://github.com/Milkywayrules/verasic-skills /tmp/verasic-skills
mkdir -p .cursor/agents .cursor/rules
cp -r /tmp/verasic-skills/cursor/agents/. .cursor/agents/
cp -r /tmp/verasic-skills/cursor/rules/.    .cursor/rules/
```

Skills-first v0.2.0: orchestration is in each skill's `SKILL.md`; there is no `cursor/commands/` directory.

**Then set up the repo (all install paths):** run `/verasic-init` in Cursor — it shows a **plan first** (profile, checklist, usage), then apply with `--yes` after you confirm. Or directly:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh              # plan only (default)
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor   # apply
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile agent    # skills.sh / Claude Code / Codex / Kiro / …
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor-hybrid  # npx skills + Cursor UX
```

Adjust the skills path prefix if your agent installs elsewhere (e.g. `.agents/skills/`). Profile spec ships in the skill: `references/install-profiles.md`. Cursor/hybrid profiles fetch UX from upstream on `--yes` (network required).

## Usage

Primary slash entries (see [references/verasic-cursor-map.md](references/verasic-cursor-map.md) for subagents and rules):

- `/verasic-bugbot` — review branch changes vs the default branch (add "uncommitted" for staged + unstaged only)
- `/verasic-secbot` — STRIDE security review on branch or uncommitted diff
- `/verasic-git-commits-audit` — audit branch commit history before push/PR
- `/verasic-fusion` — multi-model fusion (requires `mode`, `models`, question)
- `/verasic-deep-research` — ledger-backed research (requires `depth`, `output`, `source-boundary`, question)
- `/verasic-agent-disclosure` — run agent disclosure adversarial regression
- `/verasic-init` — plan setup (profile + checklist + usage), then apply with `--yes` after you confirm
- `/verasic-github-cli-init` — bootstrap GitHub CLI auth for local agents (`.envrc`, `.env.example`, verify)
- `/verasic-github-governance-init` — plan GitHub repo governance bootstrap, then apply with `--yes` after you confirm
- Commit convention needs no invocation — the always-applied rule enforces it on every commit
- GitHub env rule applies automatically before `gh` commands when installed

Full docs: [skills/verasic-fusion/README.md](skills/verasic-fusion/README.md) ·
[skills/verasic-deep-research/README.md](skills/verasic-deep-research/README.md) ·
[skills/verasic-bugbot/README.md](skills/verasic-bugbot/README.md) ·
[skills/verasic-secbot/README.md](skills/verasic-secbot/README.md) ·
[skills/verasic-git-commits-convention/README.md](skills/verasic-git-commits-convention/README.md) ·
[skills/verasic-git-commits-audit/README.md](skills/verasic-git-commits-audit/README.md) ·
[skills/verasic-agent-disclosure/README.md](skills/verasic-agent-disclosure/README.md) ·
[skills/verasic-github-cli-init/README.md](skills/verasic-github-cli-init/README.md) ·
[skills/verasic-github-governance/README.md](skills/verasic-github-governance/README.md) ·
[skills/verasic-github-governance-init/README.md](skills/verasic-github-governance-init/README.md) ·
[skills/verasic-init/README.md](skills/verasic-init/README.md)

Reference docs: [references/cursor-skills-ux.md](references/cursor-skills-ux.md) ·
[references/verasic-naming.md](references/verasic-naming.md) ·
[AGENTS.md](AGENTS.md) (maintainers)

## Security

Static scanners (Gen, Socket, Snyk on [skills.sh](https://skills.sh/milkywayrules/verasic-skills))
often flag harness skills for expected reasons — git hooks, credential docs, `curl` update checks.
See [SECURITY.md](SECURITY.md) for the trust model, expected scan signals, and credential handling.
Per-skill scanner notes:
[verasic-init](skills/verasic-init/references/scanner-notes.md) ·
[verasic-github-cli-init](skills/verasic-github-cli-init/references/scanner-notes.md) ·
[verasic-git-commits-convention](skills/verasic-git-commits-convention/references/scanner-notes.md) ·
[verasic-agent-disclosure](skills/verasic-agent-disclosure/references/scanner-notes.md) ·
[verasic-fusion](skills/verasic-fusion/references/scanner-notes.md) ·
[verasic-deep-research](skills/verasic-deep-research/references/scanner-notes.md) ·
[verasic-bugbot](skills/verasic-bugbot/references/scanner-notes.md) ·
[verasic-secbot](skills/verasic-secbot/references/scanner-notes.md) ·
[verasic-github-governance](skills/verasic-github-governance/references/scanner-notes.md) ·
[verasic-github-governance-init](skills/verasic-github-governance-init/references/scanner-notes.md)

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
├── README.md
├── AGENTS.md                         # maintainer / agent editing guide
├── SECURITY.md
├── CHANGELOG.md
├── versions.lock
├── scripts/
│   ├── check-versions.sh
│   ├── check-references.sh
│   ├── check-cursor-ux-manifest.sh
│   ├── check-bundle-pins.sh
│   ├── check-manifest-claims.sh
│   ├── check-etc-subagents.sh
│   ├── refresh-integrity.sh
│   ├── test-all.sh
│   └── test-versions-regression.sh
├── references/
│   ├── verasic-cursor-map.md         # canonical slash map
│   ├── cursor-skills-ux.md
│   ├── verasic-naming.md
│   ├── cursor-custom-subagents.md    # standalone model-pinned subagents (observed)
│   ├── adr/0001-cursor-ux-skills-first.md
│   ├── adr/0002-cursor-custom-subagents.md
│   ├── snapshots/                    # frozen PoC tables (e.g. model catalog)
│   ├── release-protocol.md
│   ├── release-notes-template.md
│   └── repo-meta.md
├── etc/
│   └── cursor/agents/                # standalone model-pinned subagents (maintainer; not product)
├── setup.sh
├── .github/workflows/                # path-filtered per skill
├── skills/                           # ← the units npx installs (11 skills, all 0.2.0)
└── cursor/                           # 4 agents + 4 rules (no commands/)
    ├── agents/
    └── rules/
```

See [references/verasic-cursor-map.md](references/verasic-cursor-map.md) for the full skill list and slash table.
