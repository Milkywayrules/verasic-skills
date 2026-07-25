# Changelog

All notable releases of the [verasic-skills](https://github.com/Milkywayrules/verasic-skills)
monorepo. Per-skill semver lives in `skills/<name>/VERSION`; this file is the human bundle
summary. Git tags (`vX.Y.Z`) pin install snapshots.

Format: bundle tag → which skills changed. See [references/release-protocol.md](references/release-protocol.md).

## Unreleased

_(none)_

## v0.2.2

**Bundle tag `v0.2.2`** — alignment release; per-skill versions unchanged at **`0.2.0`**.

- **CHANGELOG / docs** — canonical `v0.2.1` release section; install pin `@v0.2.2`
- **Governance bundle pins** — `cursor/rules/verasic-github-governance.mdc` and governance skills aligned to `@v0.2.2`
- **Integrity** — refreshed `verasic-github-governance` and `verasic-github-governance-init` hashes

### Install

```bash
npx skills add Milkywayrules/verasic-skills@v0.2.2 --skill '*' -y
bash .agents/skills/verasic-init/scripts/init.sh --yes --profile cursor-hybrid
```

See [v0.2.1](#v021) for breaking changes and migration notes.

## v0.2.1

**Bundle tag `v0.2.1`** — skills-first Cursor UX; all manifest skills **`0.2.0`**.

### Breaking changes

- **Deleted `cursor/commands/`** — nine command files merged into target `SKILL.md` files; slash = skill folder name.
- **Deleted `verasic-config`** — no repo config skill; secbot uses inlined defaults in `skills/verasic-secbot/references/config-schema.md`. Centralized config kit is **TBD / not built** (may return as npm package, Verasic Kit, or Harness Kit).
- **Renamed skills:** `verasic-security-review` → `verasic-secbot`; `verasic-github-env` → `verasic-github-cli-init`; `verasic-git-commits` → `verasic-git-commits-convention`; new `verasic-git-commits-audit`.
- **Renamed subagents:** `verasic-bug-reviewer` → `verasic-bugbot-reviewer`; `verasic-security-reviewer` → `verasic-secbot-reviewer`; `verasic-commit-auditor` → `verasic-git-commit-auditor`; `verasic-github-governance` agent → `verasic-github-governor`.
- **Renamed rules:** verasic-git-commits rule → verasic-git-commits-convention; verasic-github-env rule → verasic-github-cli-env (under cursor/rules/)
- **`setup.sh` / init** — no commands fetch; cursor-hybrid documented in install profiles.

### Retired slash names (use replacement)

| Retired | Replacement |
| --- | --- |
| `/verasic-review` | `/verasic-bugbot` |
| `/verasic-security-review` | `/verasic-secbot` |
| `/verasic-audit-commits` | `/verasic-git-commits-audit` |
| `/verasic-setup-github` | `/verasic-github-cli-init` |
| `/verasic-governance-factory` | `/verasic-github-governance-init` |
| `/verasic-disclosure-red-team` | `/verasic-agent-disclosure` |

### Retired folder / product names

- `verasic-config`, `verasic-security-review`, `verasic-github-env`, `verasic-git-commits` (monolith)

### Skills (all `0.2.0`)

- **verasic-secbot** — was security-review; inlined config defaults; spawn `verasic-secbot-reviewer`
- **verasic-bugbot** — orchestration in SKILL; cross-tip `/verasic-secbot`
- **verasic-git-commits-convention** + **verasic-git-commits-audit** — split write vs audit paths
- **verasic-github-cli-init** — was github-env
- **verasic-init** — manifest, skill-ux-map, profile fetch without commands or config
- All other manifest skills — semver `0.2.0`, integrity refreshed

### Docs

- **AGENTS.md**, **references/cursor-skills-ux.md**, **references/verasic-naming.md**, **references/verasic-cursor-map.md** (canonical slash map), **references/adr/0001-cursor-ux-skills-first.md**
- **README.md**, **SECURITY.md** — updated names; config removed; link references

### Maintainer tooling (standalone model-pinned subagents)

- **`etc/cursor/agents/`** — 16 generic `subagent-*.md` roster (source layer; manual copy to `.cursor/agents/`)
- **references/cursor-custom-subagents.md**, **references/adr/0002-cursor-custom-subagents.md**, **references/snapshots/cursor-custom-subagents-2026-07-25.md**
- Not product surface — not installed by `setup.sh` or skills.sh; no `verasic-init` manifest or integrity wiring
- **scripts/check-etc-subagents.sh** — roster frontmatter, `name:`/filename parity, `model:` catalog validation

### Infrastructure

- `.github/workflows/verasic-secbot.yml` (renamed from verasic-security-review); deleted verasic-config workflow
- `scripts/check-references.sh` — v0.2.0 basename mapping; no backward-compat aliases
- `scripts/check-cursor-ux-manifest.sh` — expects 8 files under cursor/
- `.gitignore` — ignore `.cursor/`, `.agents/`, and root `skills-lock.json`

### Install

```bash
npx skills add Milkywayrules/verasic-skills@v0.2.1 --skill '*' -y
bash .agents/skills/verasic-init/scripts/init.sh --yes --profile cursor-hybrid
```

## v0.1.12

### Skills

- **verasic-security-review** (`0.1.1`) — new: STRIDE security review on git diff, optional Semgrep/OpenGrep scanner, confidence rubric, artifact output
- **verasic-config** (`0.1.1`) — new: repo config hub — `verasic.config.ts` / `.verasicrc` schema, artifact dir scaffold, shared path resolution
- **verasic-init** (`0.1.12`) — manifest registers config + security-review; skill-ux-map uses `verasic-bug-reviewer` + `verasic-security-reviewer`; profile usage lists `/verasic-security-review`
- **verasic-bugbot** (`0.1.4`) — subagent renamed to `verasic-bug-reviewer`; cross-tip to `/verasic-security-review` for auth/crypto/webhook/input diffs

### Infrastructure

- **cursor/** — agent renames (superseded by v0.2.0 skills-first map); added secbot agent + security-review command (both retired in v0.2.0)
- CI workflows for config + security-review skills (config workflow removed in v0.2.0; security-review renamed verasic-secbot.yml)
- **verasic-bugbot.yml** — path filter updated for bug reviewer agent (renamed again in v0.2.0)
- **README.md** + **SECURITY.md** — document config + security-review skills, usage, scan signals, capability table
- **scripts/check-references.sh** — map `verasic-bug-reviewer`, `verasic-security-reviewer`, `verasic-config` cursor refs
- `.gitignore` — ignore `knowledge-base-of-king-the-user/` symlink pollution

## v0.1.11

### Skills

- **verasic-init** (`0.1.11`) — bundle bump for fusion-audit doc parity + cursor disclosure rule sync

### Docs / UX

- **README.md** — Security scanner-notes link for governance-init; hierarchy adds `check-bundle-pins.sh`, `check-manifest-claims.sh`, `verasic-bugbot.yml`, `skills/verasic-github-governance-init/references/scanner-notes.md`
- **SECURITY.md** — `verasic-deep-research` rows in Expected scan signals and What each skill can do
- **cursor/rules/verasic-agent-disclosure.mdc** — synced from skill asset (stale cursor copy)
- **verasic-git-commits README** — AGENTS.md link uses skill-relative path with install-root note

## v0.1.10

### Skills

- **verasic-github-governance** (`0.1.1`) — bundle install pin `@v0.1.10`; closes `@v0.1.8` drift from fb74bef manifest/doc parity
- **verasic-github-governance-init** (`0.1.1`) — bundle pin parity; qualified sibling-skill backtick paths; scanner-notes.md
- **verasic-init** (`0.1.10`) — bundle bump for release gates that guard manifest.txt and governance UX pins

### Infrastructure

- `scripts/check-bundle-pins.sh` — governance SKILL.md + cursor rule `@vX.Y.Z` pins must match
- `scripts/check-manifest-claims.sh` — SKILL.md manifest registration must match `manifest.txt` wiring
- both gates wired into `test-all.sh`
- **SECURITY.md** — `verasic-agent-disclosure` scan-signals row; governance-init scanner-notes link
- knowledge-base nested skill copies synced from `skills/`

## v0.1.9

### Skills

- **verasic-init** (`0.1.9`) — init-protocol documents governance manifest verify + per-skill wiring rows; cursor governance rule aligned with manifest registration

### Docs

- **verasic-github-governance-init** — bundle install note (`@v0.1.9`) for parity with governance sibling
- **SECURITY.md** — scan-signals row for governance-init

## v0.1.8

### Skills

- **verasic-github-governance** (`0.1.0`) — new: CI bootstrap, lefthook hooks, doctor, plan-gated hard protection; manifest + cursor UX
- **verasic-github-governance-init** (`0.1.0`) — new: plan-first factory orchestrator (`/verasic-governance-factory`)
- **verasic-init** (`0.1.8`) — manifest registers governance skills; cursor UX map + manifest entries for governance rule, agent, and factory command
- **verasic-agent-disclosure** (`0.1.8`) — tools-mode harness (`run-red-team-tools.sh`, 6 prompts, 6/6 pass)

### Infrastructure

- governance skills run via manifest loop in `test-all.sh` (removed separate section)
- `check-references.sh` maps `/verasic-governance-factory` to governance-init skill root

## v0.1.7

_Changelog-only release — no git tag shipped (skipped between v0.1.6 and v0.1.8)._

### Skills

- **verasic-agent-disclosure** (`0.1.7`) — Tier 1 red-team 18/18; SaaS `response-filter.sh` + `test-response-filter.sh`; Tier 2 catalog 51 prompts; policy hardening for extraction-07/docleak
- **verasic-init** (`0.1.7`) — manifest registers `verasic-agent-disclosure`; cursor UX map + manifest entries for disclosure rule and red-team command

## v0.1.6

### Skills

- **verasic-init** (`0.1.6`) — effective scope threads through profile checklist, usage, Cursor UX fetch, and versions; `--skills` cherry-pick and skills.sh partial installs are first-class; `references/skill-ux-map.txt` filters upstream UX; honest apply banners; scope section in every report; optional `not installed` framing for suite skills you did not install
- **Other manifest skills** — unchanged at `0.1.3`

### Infrastructure

- `verasic-init` regression adds scope matrix tests (`T-partial-*`, `T-map-sync`, `T-scope-banner`)

## v0.1.5

### Skills

- **verasic-init** (`0.1.5`) — confirm-first default (plan before `--yes`); install profiles (`cursor`, `agent`, `cursor-hybrid`); upstream fetch of `cursor/` UX at `v<verasic-init VERSION>` with `main` fallback (no bundled copy); `references/cursor-ux-manifest.txt` + `scripts/check-cursor-ux-manifest.sh`; Cursor UX fetch failure exits 1 with `cursor-ux` FAILED row
- **Other manifest skills** — unchanged at `0.1.3` (independent per-skill semver; bundle tag `v0.1.5` is a snapshot, not a forced bump for every skill)

### Infrastructure

- `scripts/check-cursor-ux-manifest.sh` — keeps manifest aligned with repo-root `cursor/`; wired into `test-all.sh` and `verasic-init` CI
- `SECURITY.md` — documents init cursor UX fetch and `.cursor/` writes on `--yes`
- `/verasic-init` command — two-step plan then apply

## v0.1.4

### Skills

- **verasic-github-env**, **verasic-git-commits**, **verasic-bugbot**, **verasic-fusion**, **verasic-init** — upstream SECURITY.md links point at `blob/main` (was pinned `v0.1.2`); patch bump to `0.1.3`
- **verasic-bugbot** — structural regression script; integrity manifest adds `checklists/performance.md` and `checklists/infra.md`; CI workflow `verasic-bugbot.yml`

### Infrastructure

- `scripts/check-references.sh` — validates concrete internal path refs in markdown; wired into `test-all.sh` and `verasic-versions` CI
- cursor rules: bare skill paths → full `.cursor/skills/<name>/…` references
- strict version manifest: `check-versions.sh`, `refresh-integrity.sh`, CI `verasic-versions`
- release full gate on tags: `verasic-release.yml` + `scripts/test-all.sh`
- CI for `verasic-init`, `verasic-git-commits`, `verasic-bugbot`
- install docs: Cursor + skills CLI hybrid path
- `verasic-deep-research` SECURITY.md links already on `blob/main` (VERSION `0.1.3`)

## v0.1.3

- **verasic-deep-research** — initial public release (ledger-backed research, domain packs, slash command)

## v0.1.2

- bundle baseline for fusion, init, git-commits, github-env, bugbot

## v0.1.1 / v0.1.0

- early harness skills and security docs
