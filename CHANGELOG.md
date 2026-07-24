# Changelog

All notable releases of the [verasic-skills](https://github.com/Milkywayrules/verasic-skills)
monorepo. Per-skill semver lives in `skills/<name>/VERSION`; this file is the human bundle
summary. Git tags (`vX.Y.Z`) pin install snapshots.

Format: bundle tag → which skills changed. See [references/release-protocol.md](references/release-protocol.md).

## Unreleased

_(next bundle)_

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
